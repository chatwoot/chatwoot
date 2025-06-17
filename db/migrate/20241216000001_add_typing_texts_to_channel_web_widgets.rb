class AddTypingTextsToChannelWebWidgets < ActiveRecord::Migration[7.0]
  def change
    add_column :channel_web_widgets, :typing_texts, :jsonb, default: []
    
    # Add index for better performance
    add_index :channel_web_widgets, :typing_texts, using: :gin
    
    # Set default typing texts for existing records
    reversible do |dir|
      dir.up do
        default_typing_texts = [
          'Xin chào! Tôi có thể giúp gì cho bạn?',
          'Hỗ trợ 24/7 - Luôn sẵn sàng!',
          'Chat ngay để được tư vấn miễn phí',
          'Mooly.vn - Giải pháp AI thông minh',
          'Bạn cần hỗ trợ gì không?',
          'Nhấn để bắt đầu trò chuyện',
          'AI Assistant đang chờ bạn...',
          'Tư vấn nhanh - Phản hồi tức thì'
        ]
        
        execute <<-SQL
          UPDATE channel_web_widgets 
          SET typing_texts = '#{default_typing_texts.to_json}'::jsonb 
          WHERE typing_texts IS NULL OR typing_texts = '[]'::jsonb
        SQL
      end
    end
  end
end
