require 'timeout'

module Ramaze::Dispatcher
  RESPONSE = Ramaze::Response.create

  class << self
    def handle orig_request, orig_response
      return create_response(orig_response, orig_request)
    rescue Object => e
      if Ramaze::Global.error_page
        if Ramaze::Error.constants.include?(e.class.name.split('::').last)
          Ramaze::Logger.error e.message
        else
          Ramaze::Logger.error e
        end
        return Ramaze::Error::Response.new(e)
      else
        Ramaze::Logger.error e
        return RESPONSE.clear
      end
    end

    def create_response orig_response, orig_request
      response = Thread.current[:response] = RESPONSE.clear
      request  = Thread.current[:request]  = Ramaze::Request.new(orig_request)
      session  = Thread.current[:session]  = Ramaze::Session.new(request)

      path = request.request_path.squeeze('/')
      Ramaze::Logger.debug "Request from #{request.remote_addr}: #{path}"

      the_path = $:.map{|way| File.join(way, 'public', path) }

      if file = the_path.find{|way| File.exist?(way) and File.file?(way)}
        response.head['Content-Type'] = ''
        response.out = File.read(file)
      else
        controller, action, params = resolve_controller(path)
        response.out = handle_controller(request, controller, action, params)
        response.head['Set-Cookie'] = session.export
      end

      response
    end

    def resolve_action controller, paraction
      Ramaze::Logger.info :resolve_action, controller, paraction

      meths = controller.instance_methods(false)

      track = paraction.dup
      tracks = []
      action = false

      track.each do |atom|
        atom = [tracks.last.to_s, atom]
        atom.delete('')
        tracks << atom.join('__')
      end

      tracks.unshift 'index'

      until action or tracks.empty?
        current = tracks.pop
        if meths.include?(current)
          arity = controller.instance_method(current).arity
          params = (paraction - current.split('__'))

          if params.size == arity
            return current, params
          elsif arity < 0 and arity + params.size >= 0
            return current, params
          else
            raise Ramaze::Error::WrongParameterCount
          end
        end
      end
    end

    def resolve_controller path
      Ramaze::Logger.info :resolve_controller, path.inspect
      track = path.split('/')
      controller = false
      action = false
      tracks = []

      track.unshift '/'

      track.each do |atom|
        tracks << File.join(tracks.last.to_s, atom)
      end

      until controller and action or tracks.empty?
        current = tracks.pop
        paraction = path.gsub(/^#{current}/, '').split('/')
        paraction.delete('')
        if controller = Ramaze::Global.mapping[current]
          action, params = resolve_action controller, paraction
        end
      end

      raise Ramaze::Error::NoController, "No Controller found for #{path}" unless controller
      raise Ramaze::Error::NoAction, "No Action found for #{path}" unless action

      return controller, action, params
    end

    def handle_controller request, controller, action, params
      if Ramaze::Global.cache
        Global.out_cache ||= {}

        key = [controller.__id__, action, params]
        out = Global.out_cache[key]

        return out if out

        Ramaze::Logger.debug "Compiling Action: #{action} #{params.join(', ')}"
        Global.out_cache[key] = request_controller request, controller, action, params
      else
        controller.handle_request(request, action, *params)
      end
    end
  end
end
