<template>
  <div class="map message-text__wrap">
    <img
      :src="locUrl"
    />
    <span class="locname">{{label || ' '}}</span>
    <span class="time">{{readableTime}}</span>
  </div>
</template>

<script>
export default {
  props: [
    'lat',
    'lng',
    'label',
    'readableTime',
  ],
  data() {
    return {
      accessToken: 'pk.eyJ1IjoiY2hhdHdvb3QiLCJhIjoiY2oyazVsM3d0MDBmYjJxbmkyYXlwY3hzZyJ9.uWUdfItb0sSZQ4nfwlmuPg',
      zoomLevel: 14,
      mapType: 'mapbox.streets',
      apiEndPoint: 'https://api.mapbox.com/v4/',
      h: 100,
      w: 150,
    };
  },
  computed: {
    locUrl() {
      const { apiEndPoint, mapType, lat, lng, zoomLevel, h, w, accessToken } = this;
      return `${apiEndPoint}${mapType}/${lng},${lat},${zoomLevel}/${w}x${h}.png?access_token=${accessToken}`;
    },
  },
};
</script>
