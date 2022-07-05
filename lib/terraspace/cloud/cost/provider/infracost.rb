module Terraspace::Cloud::Cost::Provider
  class Infracost
    extend Memoist
    include Terraspace::Util::Popen

    def name
      "infracost"
    end

    def run(output_dir=".terraspace-cache/.cache2/cost")
      commands = [
        "infracost breakdown --path . --format json --out-file #{output_dir}/cost.json",
        "infracost output --path #{output_dir}/cost.json --format html --out-file #{output_dir}/cost.html",
        "infracost output --path #{output_dir}/cost.json --format table --out-file #{output_dir}/cost.text",
      ]
      commands.each do |command|
        logger.debug "=> #{command}"

        popen(command, filter: "Output saved to ")
        if command.include?(".text")
          logger.info IO.read("#{output_dir}/cost.text")
          logger.info "\n"
        end
      end
    end

    def version
      out = `infracost --version`.strip # Infracost v0.10.6
      md = out.match(/ v(.*)/)
      md ? md[1] : out
    end
    memoize :version
  end
end
