class SetDefaultValueForWhatsappScript < ActiveRecord::Migration[7.0]
  def up
    add_column :channel_whatsapp, :web_widget_script, :text unless ActiveRecord::Base.connection.column_exists?(:channel_whatsapp,
                                                                                                                :web_widget_script)
    Channel::Whatsapp.reset_column_information
    Channel::Whatsapp.find_each do |record|
      formattedPhoneNumber = record.phone_number[1..]
      account = Inbox.find_by(channel_id: record.id)
      account_name = account&.name.to_s.strip.gsub('"', '\"') # escape quotes for JS

      script = %{
<script>
  (function(d, t) {
    var position = 'right';
    var config = {
      link: "https://wa.me/#{formattedPhoneNumber}?text=Hello%20there!",
      user: {
        name: "#{account_name}",
        avatar: "https://upload.wikimedia.org/wikipedia/commons/6/6b/WhatsApp.svg",
        status: ""
      },
      text: "Hey There 👋<br><br>We're here to help, so let us know what's up and we'll be happy to find a solution 🤓",
      button_text: ""
    };
    var g = d.createElement(t), s = d.getElementsByTagName(t)[0];
    g.src = "https://cdn.jsdelivr.net/gh/onehashai/onehash-chat@whatsapp-widget/public/whatsapp-widget-right.min.js";
    g.defer = true;
    g.async = true;
    s.parentNode.insertBefore(g, s);
    g.onload = function() {
      new WAChatBox(config);
    };
  })(document, "script");
</script>
  }

      record.update_column(:web_widget_script, script)
    end
  end

  def down
    remove_column :channel_whatsapp, :web_widget_script
  end
end
