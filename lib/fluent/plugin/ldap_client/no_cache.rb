# frozen_string_literal: true

module Fluent
  module Plugin
    module LdapClient
      class NoCache
        def get(*args, **kvargs)
          yield(*args, **kvargs) if block_given?
        end
      end
    end
  end
end
