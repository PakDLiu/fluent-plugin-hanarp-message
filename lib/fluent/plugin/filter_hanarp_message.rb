require 'fluent/plugin/filter'
require 'json'
require 'net/http'
require 'openssl'

module Fluent::Plugin
  class HanarpMessage < Filter
    Fluent::Plugin.register_filter("hanarp_message", self)

    config_param :ucsHostNameKey, :string
    config_param :coloregion, :string

    def filter(tag, time, record)

      split = record["message"].split(": ")

      host = record[ucsHostNameKey]

      message = split[4]
      event = determineEvent(message)

      temp3 = split[3]
      stageSplit = temp3.split(" ")
      stage = determineStage(stageSplit[1])

      chassis = message[/chassis-(\d)/,1]

      blade = message[/blade-(\d)/,1]

      serviceProfile = record["serviceProfile"]

      machineId = "Cisco_UCS:#{coloregion}:#{serviceProfile}"

      d = Data.new(machineId, host, chassis, blade, serviceProfile, stage, message)
      m = Message.new(time, event, d)
      record["message"] = m.to_json
      record
    end

    def determineEvent(message)
      case message
        when /Power-on/
          event = "Boot"
        when /Soft shutdown/
          event = "Soft Shutdown"
        when /Hard shutdown/
          event = "Hard Shutdown"
        when /Power-cycle/
          event = "Restart"
      end
      event
    end

    def determineStage(stage)
      case stage
        when /BEGIN/
          stage = "Begin"
        when /END/
          stage = "End"
      end
      stage
    end
  end

  class Message
    def initialize(timestamp, event, data)
      @timestamp = timestamp
      @event = event
      @data = data
    end

    def to_json(*a)
      {
        timestamp: @timestamp,
        event: @event,
        data: @data
      }.to_json(*a)
    end
  end

  class Data
    def initialize(machineId, hostname, chassis, blade, serviceProfile, stage, message)
      @machineId = machineId
      @hostname = hostname
      @chassis = chassis
      @blade = blade
      @serviceProfile = serviceProfile
      @stage = stage
      @message = message
    end

    def to_json(*a)
      {
        machineId: @machineId,
        hostname: @hostname,
        chassis: @chassis,
        blade: @blade,
        serviceProfile: @serviceProfile,
        stage: @stage,
        message: @message
      }.to_json(*a)
    end
  end
end
