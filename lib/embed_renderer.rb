module EmbedRenderer
  def self.youtube(video_id)
    %(
      <div style="position: relative; padding-bottom: 62.5%; height: 0;">
       <iframe
        src="https://www.youtube-nocookie.com/embed/#{video_id}"
        frameborder="0"
        style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;"
        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
        allowfullscreen></iframe>
      </div>
    )
  end

  def self.loom(video_id)
    %(
      <div style="position: relative; padding-bottom: 62.5%; height: 0;">
        <iframe
         src="https://www.loom.com/embed/#{video_id}"
         frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen
         style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;"></iframe>
      </div>
    )
  end

  def self.vimeo(video_id)
    %(
      <div style="position: relative; padding-bottom: 62.5%; height: 0;">
       <iframe
        src="https://player.vimeo.com/video/#{video_id}?dnt=true"
        frameborder="0"
        allow="autoplay; fullscreen; picture-in-picture"
        allowfullscreen
        style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;"></iframe>
       </div>
    )
  end

  def self.video(link_url)
    %(
      <video width="640" height="360" controls>
        <source src="#{link_url}" type="video/mp4">
        Your browser does not support the video tag.
      </video>
    )
  end

  # Generates an HTML embed for a Wistia video.
  # @param wistia_match [MatchData] A match object from the WISTIA_REGEX regex, where wistia_match[2] contains the video ID.
  def self.wistia(video_id)
    %(
      <div style="position: relative; padding-bottom: 56.25%; height: 0;">
        <script src="https://fast.wistia.com/player.js" async></script>
        <script src="https://fast.wistia.com/embed/#{video_id}.js" async type="module"></script>
        <style>
          wistia-player[media-id='#{video_id}']:not(:defined) {
            background: center / contain no-repeat url('https://fast.wistia.com/embed/medias/#{video_id}/swatch');
            display: block;
            filter: blur(5px);
            padding-top:56.25%;
          }
        </style>
        <wistia-player
          media-id="#{video_id}"
          aspect="1.7777777777777777"
          style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;">
        </wistia-player>
      </div>
    )
  end

  def self.arcade(video_id)
    %(
    <div style="position: relative; padding-bottom: 62.5%; height: 0;">
      <iframe
        src="https://app.arcade.software/embed/#{video_id}"
        frameborder="0"
        webkitallowfullscreen
        mozallowfullscreen
        allowfullscreen
        allow="fullscreen"
        style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;">
      </iframe>
    </div>
  )
  end

  def self.bunny(library_id, video_id)
    %(
      <div style="position: relative; padding-top: 56.25%;">
        <iframe
          src="https://iframe.mediadelivery.net/embed/#{library_id}/#{video_id}?autoplay=false&loop=false&muted=false&preload=true&responsive=true"
          title="Bunny video player"
          loading="lazy"
          style="border: 0; position: absolute; top: 0; height: 100%; width: 100%;"
          allow="accelerometer; gyroscope; autoplay; encrypted-media; picture-in-picture;"
          allowfullscreen>
        </iframe>
      </div>
    )
  end
end
