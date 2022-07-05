module Terraspace::Cloud
  class Cost < Base
    def create(uid:)
      return unless Terraspace.cloud?
      return unless Terraspace.config.cloud.cost.enabled

      cani?
      build
      folder = Folder.new(@options.merge(type: "cost"))
      upload = folder.upload_data # returns upload record
      api.create_cost(
        upload_id: upload['id'],
        stack_uid: upload['stack_id'], # use stack_uid since stack_id is friendly url name
        uid: uid,
        cost: cost_attrs,
      )
    rescue Terraspace::NetworkError => e
      logger.warn "WARN: #{e.class} #{e.message}"
      logger.warn "WARN: Unable to save data to Terraspace cloud"
    end

    # different from stage_attrs
    def cost_attrs
      {
        provider: provider.name, # IE: infracost
        provider_version: provider.version,
        terraspace_version: check.terraspace_version,
        terraform_version: check.terraform_version,
      }
    end

    def cani?
      api.create_cost(cani: 1)
    end

    def build
      clean_cache2_stage
      # .terraspace-cache/dev/stacks/demo
      Dir.chdir(@mod.cache_dir) do
      logger.info "Running cost estimate..."
        provider.run
      end
    end

    def provider
      Terraspace::Cloud::Cost::Provider::Infracost.new # only provider currently supported
    end
    memoize :provider
  end
end
