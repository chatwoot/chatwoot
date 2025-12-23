# frozen_string_literal: true

require 'erb'

module OutputToHTML
  TEMPLATE_HEADER = <<"EOT"
  <div>
    All times are rounded to the nearest thousandth for display purposes. Speedups next to each time are computed
    before any rounding occurs. Also, all speedup calculations are computed by comparing a given time against
    the very first column (which is always the default ActiveRecord::Base.create method.
   </div>
EOT

  TEMPLATE = <<"EOT"
 <style>
 td#benchmarkTitle {
   border: 1px solid black;
   padding: 2px;
   font-size: 0.8em;
   background-color: black;
   color: white;
 }
 td#benchmarkCell {
   border: 1px solid black;
   padding: 2px;
   font-size: 0.8em;
 }
 </style>
   <table>
     <tr>
       <% columns.each do |col| %>
         <td id="benchmarkTitle"><%= col %></td>
       <% end %>
     </tr>
     <tr>
       <% times.each do |time| %>
         <td id="benchmarkCell"><%= time %></td>
       <% end %>
     </tr>
     <tr><td>&nbsp;</td></tr>
   </table>
EOT

  def self.output_results( filename, results )
    html = ''
    results.each do |result_set|
      columns = []
      times = []
      result_set.each do |result|
        columns << result.description
        if result.failed
          times << "failed"
        else
          time = result.tms.real.round_to( 3 )
          speedup = ( result_set.first.tms.real / result.tms.real ).round
          times << (result == result_set.first ? time.to_s : "#{time} (#{speedup}x speedup)")
        end
      end

      template = ERB.new( TEMPLATE, 0, "%<>")
      html << template.result( binding )
    end

    File.open( filename, 'w' ) { |file| file.write( TEMPLATE_HEADER + html ) }
  end
end
