class Terraspace::CLI
  class Up < Base
    include TfcConcern
    include Concerns::PlanPath

    def run
      build
      plan if @options[:yes] && !@options[:plan] && !tfc?
      apply
    end

  private
    def plan
      if Terraspace.cloud? && !@options[:plan]
        @options[:plan] = plan_path # for terraform apply
        @options[:out] = plan_path  # for terraform plan
      end

      cloud_update.cani?
      plan = Plan.new(@options)
      success = plan.plan_only
      unless success
        create_cloud_records(success)
        logger.error plan.error_message.color(:red)
        exit 1
      end
    end

    def apply
      commander = Commander.new("apply", @options)
      success = commander.run
      create_cloud_records(success)
      unless success
        logger.error commander.error_message.color(:red)
        exit 1
      end
    end

    def create_cloud_records(success)
      update = cloud_update.create(success)
      cloud_cost.create(uid: update['data']['id'])
    end

    def cloud_update
      Terraspace::Cloud::Update.new(@options.merge(stack: @mod.name, kind: "apply"))
    end
    memoize :cloud_update

    def cloud_cost
      Terraspace::Cloud::Cost.new(@options.merge(stack: @mod.name, kind: "apply"))
    end
    memoize :cloud_cost

    # must build to compute tfc?
    def build
      Terraspace::Builder.new(@options).run
      @options[:build] = false
    end
  end
end
