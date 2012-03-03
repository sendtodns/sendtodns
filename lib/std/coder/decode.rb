module Std
  module Decode
    extend self

    def assemble_part(part_piece)
      part_cut = part_piece.to_s.index("\t\"") + 2
      return part_piece.to_s.slice(part_cut..-3).to_s.gsub('" "', "\n") + "\n"
    end

    def sort_part(part)
      return part.split("\n").sort_by { |key| key.split(/(\d+)/).map { |v| v =~ /\d/ ? v.to_i : v } }.join("\n").to_s.gsub(/^\d+\s+/, "").to_s
    end

  end
end
