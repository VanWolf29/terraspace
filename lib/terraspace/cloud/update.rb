module Terraspace::Cloud
  class Update < Base
    def create(success)
      return unless Terraspace.cloud?
      return unless record?

      build(success)
      folder = Folder.new(@options.merge(type: @kind))
      upload = folder.upload_data # returns upload record
      result = api.create_update(
        upload_id: upload['id'],
        stack_uid: upload['stack_id'], # use stack_uid since stack_id is friendly url name
        update: stage_attrs(success),
      )
      url = terraspace_cloud_info(result)
      pr_comment(url)
      result
    end

    def build(success)
      clean_cache2_stage
      # .terraspace-cache/dev/stacks/demo
      Dir.chdir(@mod.cache_dir) do
        cache2_path = ".terraspace-cache/.cache2/#{@kind}"
        FileUtils.mkdir_p(cache2_path)

        IO.write("#{cache2_path}/#{@kind}.log", Terraspace::Logger.logs)
        return unless success

        sh "terraform state pull > #{cache2_path}/state.json"
        sh "terraform output -json > #{cache2_path}/output.json"
      end
    end

    def cani?
      return true unless Terraspace.cloud?
      api.create_update(cani: 1)
    end
  end
end
