require 'reqless'
require 'reqless/worker'
require 'qmore/configuration'
require 'qmore/persistence'
require 'qmore/attributes'
require 'qmore/reservers'

module Qmore
  def self.client=(client)
    @client = client
  end

  def self.client
    @client ||= Reqless::Client.new
  end

  def self.configuration
    @configuration ||= Qmore::LegacyConfiguration.new(Qmore.persistence)
  end

  def self.configuration=(configuration)
    @configuration = configuration
  end

  def self.persistence
    @persistence ||= Qmore::Persistence::Reqless.new(self.client)
  end

  def self.persistence=(manager)
    @persistence = manager
  end

  def self.monitor
    @monitor ||= Qmore::Persistence::Monitor.new(self.persistence, 120)
  end

  def self.monitor=(monitor)
    @monitor = monitor
  end
end

module Reqless
  module JobReservers
    QmoreReserver = Qmore::Reservers::Default
  end
end
ENV['JOB_RESERVER'] ||= 'QmoreReserver'
