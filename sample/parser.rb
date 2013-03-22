module Fluent
  class SnmpInput
    def parser opts={}
      record = {}
      opts[:input].each do |vb|
        record["name"] = vb.name.to_s
        record["value"] = vb.value.to_s
        Engine.emit opts[:tag], opts[:time], record
      end
    end
  end
end

