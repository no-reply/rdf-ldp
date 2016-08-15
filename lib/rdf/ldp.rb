require 'rdf'
require 'rdf/vocab'

require 'rdf/ldp/version'

require 'rdf/ldp/resource'
require 'rdf/ldp/rdf_source'
require 'rdf/ldp/non_rdf_source'
require 'rdf/ldp/container'
require 'rdf/ldp/direct_container'
require 'rdf/ldp/indirect_container'

module RDF
  ##
  # This module implements a basic domain model for Linked Data Platform (LDP).
  # Its classes allow CRUD operations on LDP RDFSources, NonRDFSources and
  # Containers, while presenting an interface appropriate for consumption by
  # Rack servers.
  #
  # @see RDF::LDP::Resource
  # @see http://www.w3.org/TR/ldp/ for the Linked Data platform specification
  module LDP
    ##
    # Interaction models are in reverse order of preference for POST/PUT
    # requests; e.g. if a client sends a request with Resource, RDFSource, and
    # BasicContainer headers, the server gives a basic container.
    INTERACTION_MODELS = {
      RDF::Vocab::LDP.Resource => RDF::LDP::RDFSource,
      RDF::LDP::RDFSource.to_uri => RDF::LDP::RDFSource,
      RDF::LDP::Container.to_uri => RDF::LDP::Container,
      RDF::Vocab::LDP.BasicContainer => RDF::LDP::Container,
      RDF::LDP::DirectContainer.to_uri => RDF::LDP::DirectContainer,
      RDF::LDP::IndirectContainer.to_uri => RDF::LDP::IndirectContainer,
      RDF::LDP::NonRDFSource.to_uri => RDF::LDP::NonRDFSource
    }.freeze

    CONTAINER_CLASSES = {
      basic:    RDF::Vocab::LDP.BasicContainer.freeze,
      direct:   RDF::LDP::DirectContainer.to_uri.freeze,
      indirect: RDF::LDP::IndirectContainer.to_uri.freeze
    }.freeze

    CONSTRAINED_BY = RDF::Vocab::LDP.constrainedBy.freeze

    ##
    # A base class for HTTP request errors.
    #
    # This and its subclasses are caught and handled by Rack::LDP middleware.
    # When a `RequestError` is caught by server middleware, its `#status` can be
    # used as a response code and `#headers` may be added to (or replace) the
    # existing HTTP headers.
    class RequestError < RuntimeError
      STATUS = 500

      def status
        self.class::STATUS
      end

      def headers
        uri =
          'https://github.com/no-reply/rdf-ldp/blob/master/CONSTRAINED_BY.md'
        { 'Link' => "<#{uri}>;rel=\"#{CONSTRAINED_BY}\"" }
      end
    end

    ##
    # An error for 400 Bad Request responses
    #
    # @see RDF::LDP::RequestError
    class BadRequest < RequestError
      STATUS = 400
    end

    ##
    # An error for 404 NotFound responses
    #
    # @see RDF::LDP::RequestError
    class NotFound < RequestError
      STATUS = 404
    end

    ##
    # An error for 405 MethodNotAllowed responses
    #
    # @see RDF::LDP::RequestError
    class MethodNotAllowed < RequestError
      STATUS = 405
    end

    ##
    # An error for 406 NotAcceptable responses
    #
    # @see RDF::LDP::RequestError
    class NotAcceptable < RequestError
      STATUS = 406
    end

    ##
    # An error for 409 Conflict responses
    #
    # @see RDF::LDP::RequestError
    class Conflict < RequestError
      STATUS = 409
    end

    ##
    # An error for 410 Gone responses
    #
    # @see RDF::LDP::RequestError
    class Gone < RequestError
      STATUS = 410
    end

    ##
    # An error for 412 Precondition Failed responses
    #
    # @see RDF::LDP::RequestError
    class PreconditionFailed < RequestError
      STATUS = 412
    end

    ##
    # An error for 415 Unsupported Media Type responses
    #
    # @see RDF::LDP::RequestError
    class UnsupportedMediaType < RequestError
      STATUS = 415
    end
  end
end
