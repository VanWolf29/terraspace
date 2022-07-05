class Terraspace::CLI
  class Plan < Base
    include TfcConcern
    include Concerns::PlanPath

    def run
      success = plan_only
      plan = cloud_plan.create(success)
      cloud_cost.create(uid: plan['data']['id'])
      logger.info "Terraspace Cloud #{plan['data']['attributes']['url']}"
      unless success
        logger.error commander.error_message.color(:red)
        exit 1
      end
    end

    def plan_only
      if Terraspace.cloud? && !@options[:out]
        @options[:out] = plan_path
      end
      cloud_plan.setup
      success = commander.run
      copy_out_file_to_root
      success
    end

    def commander
      Commander.new("plan", @options)
    end
    memoize :commander
    delegate :error_message, to: :commander

    def copy_out_file_to_root
      file = @mod.out_option
      return if !file || @options[:copy_to_root] == false
      return if file =~ %r{^/} # not need to copy absolute path

      name = file.sub("#{Terraspace.root}/",'')
      src = "#{@mod.cache_dir}/#{name}"
      dest = name
      return unless File.exist?(src) # plan wont exists if the plan errors
      FileUtils.mkdir_p(File.dirname(dest))
      FileUtils.cp(src, dest)
      !!dest
    end

    def cloud_plan
      Terraspace::Cloud::Plan.new(@options.merge(stack: @mod.name, kind: kind))
    end
    memoize :cloud_plan

    def cloud_cost
      Terraspace::Cloud::Cost.new(@options.merge(stack: @mod.name, kind: kind))
    end
    memoize :cloud_cost

    def kind
      return "apply" if @options.nil?
      is_destroy = @options[:args]&.include?('--destroy') || @options[:destroy]
      is_destroy ? "destroy" : "apply"
    end
  end
end
