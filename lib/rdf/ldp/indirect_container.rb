module RDF::LDP
  ##
  # An extension of `RDF::LDP::DirectContainer` implementing indirect 
  # containment. Adds the concept of an inserted content relation to the 
  # features of the direct container.
  #
  # Clients MUST provide exactly one `ldp:insertedContentRelation` statement in
  # each Indirect Container. If no `#inserted_content_relation` is given by the 
  # client, we default to `ldp:MemberSubject`. If more than one is present,
  #
  # Attempts to POST resources without the appropriate content relation (or 
  # with more than one) to an Indirect Container will fail with `Not 
  # Acceptable`. LDP-NR's cannot be added since indirect membership is not well
  # defined for them, per _LDP 5.5.1.2_.
  #
  # @see http://www.w3.org/TR/ldp/#h-ldpic-indirectmbr for an explanation if 
  #   indirect membership and limitiations surrounding LDP-NRs.
  # @see http://www.w3.org/TR/ldp/#dfn-linked-data-platform-indirect-container
  #   definition of LDP Indirect Container
  class IndirectContainer < DirectContainer
    def self.to_uri
      RDF::Vocab::LDP.IndirectContainer
    end

    ##
    # @return [RDF::URI] a URI representing the container type
    def container_class
      CONTAINER_CLASSES[:indirect]
    end

    ##
    # Gives the inserted content relation for the indirect container. If none is
    # present in the container state, we add `ldp:MemberSubject`, effectively 
    # treating this LDP-IC as an LDP-DC.
    #
    # @return [RDF::URI] the inserted content relation; either a predicate term
    #   or `ldp:MemberSubject`
    #
    # @raise [RDF::LDP::NotAcceptable] if multiple inserted content relations 
    #   exist.
    #
    # @see http://www.w3.org/TR/ldp/#dfn-membership-triples
    def inserted_content_relation
      statements = inserted_content_statements
      case statements.count
      when 0
        graph << RDF::Statement(subject_uri, 
                                RDF::Vocab::LDP.indirectContentRelation, 
                                RDF::Vocab::LDP.MemberSubject)
        RDF::Vocab::LDP.MemberSubject
      when 1
        statements.first.object
      else
        raise NotAcceptable.new('An LDP-IC MUST have exactly ' \
                                'one inserted content relation triple; found ' \
                                "#{statements.count}.")
      end
    end

    private

    def inserted_content_statements
      graph.statements.select do |st| 
        st.subject == subject_uri && 
          st.predicate == RDF::Vocab::LDP.indirectContentRelation
      end
    end
    
    def process_membership_resource(resource, &block)
      resource = member_derived_uri(resource)
      super(resource, &block)
    end
    
    def member_derived_uri(resource)
      predicate = inserted_content_relation
      return resource.to_uri if predicate == RDF::Vocab::LDP.MemberSubject

      raise NotAcceptable.new("#{resource.to_uri} is an LDP-NR; cannot add " \
                              'it to an IndirectContainer with a content ' \
                              'relation.') if resource.non_rdf_source?
                              
      resource

      statements = resource.graph.query([resource.subject_uri, predicate, :o])
      case statements.count
      when 1
        statements.first.object
      else
        raise NotAcceptable.new("#{statements.count} inserted content" \
                                "#{predicate} found on #{resource.to_uri}")
      end
    end
  end
end
