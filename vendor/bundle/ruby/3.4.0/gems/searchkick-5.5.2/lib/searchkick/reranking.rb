module Searchkick
  module Reranking
    def self.rrf(first_ranking, *rankings, k: 60)
      rankings.unshift(first_ranking)
      rankings.map!(&:to_ary)

      ranks = []
      results = []
      rankings.each do |ranking|
        ranks << ranking.map.with_index.to_h { |v, i| [v, i + 1] }
        results.concat(ranking)
      end

      results =
        results.uniq.map do |result|
          score =
            ranks.sum do |rank|
              r = rank[result]
              r ? 1.0 / (k + r) : 0.0
            end

          {result: result, score: score}
        end

      results.sort_by { |v| -v[:score] }
    end
  end
end
