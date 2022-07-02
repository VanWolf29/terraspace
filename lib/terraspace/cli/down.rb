class Terraspace::CLI
  class Down < Base
    include TfcConcern
    include Concerns::PlanPath

    def run
      cloud_update.cani?
      plan if @options[:yes] && !tfc?
      destroy
    end

  private
    def plan
      if Terraspace.cloud? && !@options[:out]
        @options[:out] = plan_path
      end
      plan = Plan.new(@options.merge(destroy: true))
      success = plan.plan_only
      unless success
        cloud_update.create(success)
        logger.error plan.error_message.color(:red)
        exit 1
      end
    end

    def destroy
      commander = Commander.new("destroy", @options.merge(command: "down"))
      success = commander.run
      cloud_update.create(success)

      if success && @options[:destroy_workspace]
        Terraspace::Terraform::Tfc::Workspace.new(@options).destroy
      end
      unless success
        logger.error commander.error_message.color(:red)
        exit 1
      end
    end

    def cloud_update
      Terraspace::Cloud::Update.new(@options.merge(stack: @mod.name, kind: "destroy"))
    end
    memoize :cloud_update
  end
end
