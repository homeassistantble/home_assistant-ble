require 'home_assistant/ble/version'
require 'ble'
require 'mash'
require 'net/http'
require 'uri'
require 'json'

module HomeAssistant
  module Ble
    class Detector
      attr_reader :config, :known_devices

      def initialize(config)
        @config = Mash.new(config)
        @known_devices = {}
      end

      # polling interval
      def interval
        config['interval'] || 30
      end

      # time after which a device is considered as disappeared
      def grace_period
        config['grace_period'] || 60
      end

      def home_assistant_url
        config['home_assistant_url'] || 'http://localhost:8123'
      end

      def home_assistant_password
        config['home_assistant_password']
      end

      def home_assistant_devices
        # TODO: read this from HA known_devices.yml
        config['home_assistant_devices'] || {}
      end

      def run
        loop do
          detect_devices
          clean_devices
          debug "Will sleep #{interval}s before relisting devices"
          sleep interval
        end
      end

      private

      def log(message)
        puts message
      end

      def debug(message)
        log 'Set DEBUG environment variable to activate debug logs' unless ENV['DEBUG'] || @debug_tip
        @debug_tip = true
        print '(debug) '
        puts message if ENV['DEBUG']
      end

      def detect_devices
        adapter.devices.each do |name|
          unless known_devices.key?(name)
            log "Just discovered #{name}"
            home_assistant_devices[name] && update_home_assistant(home_assistant_devices[name], :home)
          end
          known_devices[name] = Time.now
        end
      end

      def clean_devices
        disappeared = (known_devices.keys - adapter.devices).select do |name|
          Time.now - known_devices[name] > grace_period
        end
        disappeared.each do |name|
          known_devices.delete(name).tap do |last_seen|
            log "#{name} has disappeared (last seen #{last_seen})"
            home_assistant_devices[name] && update_home_assistant(home_assistant_devices[name], :not_home)
          end
        end
      end

      def update_home_assistant(ha_name, state)
        uri = URI.join(home_assistant_url, "api/states/device_tracker.#{ha_name}")
        request = Net::HTTP::Post.new(uri)
        request.content_type = 'application/json'
        request['X-Ha-Access'] = home_assistant_password if home_assistant_password
        request.body = JSON.dump('state' => state)
        req_options = { use_ssl: uri.scheme == 'https' }

        response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
          http.request(request)
        end

        if response.code.to_i == 200
          debug "State update #{state} sent to HA for #{ha_name}"
          debug response.body
        else
          log "Error while sending #{state} to HA form #{ha_name}."
          log "URI was: #{uri}. Response was:"
          log response.body
        end
      end

      def adapter
        @adapter ||= begin
                       iface = BLE::Adapter.list.first
                       debug "Selecting #{iface} to listen for bluetooth events"
                       raise 'Unable to find a bluetooth device' unless iface
                       BLE::Adapter.new(iface).tap do |a|
                         debug 'Activating discovery'
                         a.start_discovery
                       end
                     end
      end
    end
  end
end
