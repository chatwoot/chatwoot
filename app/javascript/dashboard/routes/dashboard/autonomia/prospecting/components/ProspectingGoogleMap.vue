<script setup>
import { nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  apiKey: {
    type: String,
    default: '',
  },
  center: {
    type: Object,
    default: null,
  },
  radius: {
    type: Number,
    default: 0,
  },
  leads: {
    type: Array,
    default: () => [],
  },
  heightClass: {
    type: String,
    default: 'h-80',
  },
});

const emit = defineEmits(['selectLead']);
const { t } = useI18n();

const GOOGLE_MAPS_SCRIPT_ID = 'autonomia-prospecting-google-maps';
let googleMapsScriptPromise = null;

const mapElement = ref(null);
const isReady = ref(false);
const loadError = ref('');
let map = null;
let circle = null;
let markers = [];

const loadGoogleMaps = apiKey => {
  if (!apiKey) return Promise.reject(new Error('missing_api_key'));
  if (window.google?.maps) return Promise.resolve();
  if (googleMapsScriptPromise) return googleMapsScriptPromise;

  googleMapsScriptPromise = new Promise((resolve, reject) => {
    const existingScript = document.getElementById(GOOGLE_MAPS_SCRIPT_ID);
    if (existingScript) {
      existingScript.addEventListener('load', resolve, { once: true });
      existingScript.addEventListener('error', reject, { once: true });
      return;
    }

    const script = document.createElement('script');
    script.id = GOOGLE_MAPS_SCRIPT_ID;
    script.async = true;
    script.defer = true;
    script.src = `https://maps.googleapis.com/maps/api/js?key=${encodeURIComponent(apiKey)}`;
    script.onload = resolve;
    script.onerror = reject;
    document.head.appendChild(script);
  });

  return googleMapsScriptPromise;
};

const clearMarkers = () => {
  markers.forEach(marker => marker.setMap(null));
  markers = [];
};

const clearCircle = () => {
  if (circle) circle.setMap(null);
  circle = null;
};

const normalizedCenter = () => {
  if (props.center?.lat == null || props.center?.lng == null) return null;

  return {
    lat: Number(props.center.lat),
    lng: Number(props.center.lng),
  };
};

const leadsWithCoordinates = () =>
  props.leads.filter(lead => lead.latitude != null && lead.longitude != null);

const getZoomForRadius = radiusMeters => {
  const radiusKm = Number(radiusMeters || 0) / 1000;
  if (radiusKm <= 2) return 14;
  if (radiusKm <= 5) return 13;
  if (radiusKm <= 10) return 12;
  if (radiusKm <= 20) return 11;
  if (radiusKm <= 35) return 10;
  return 9;
};

const renderMap = async () => {
  if (!isReady.value || !mapElement.value || !window.google?.maps) return;

  await nextTick();

  const center = normalizedCenter();
  const leads = leadsWithCoordinates();
  const fallbackCenter =
    center ||
    (leads[0]
      ? { lat: Number(leads[0].latitude), lng: Number(leads[0].longitude) }
      : { lat: -23.5505, lng: -46.6333 });

  if (!map) {
    map = new window.google.maps.Map(mapElement.value, {
      center: fallbackCenter,
      zoom: getZoomForRadius(props.radius),
      mapTypeControl: false,
      streetViewControl: false,
      fullscreenControl: true,
      zoomControl: true,
    });
  }

  clearMarkers();
  clearCircle();

  const bounds = new window.google.maps.LatLngBounds();
  let hasBounds = false;

  if (center) {
    bounds.extend(center);
    hasBounds = true;
  }

  leads.forEach((lead, index) => {
    const position = {
      lat: Number(lead.latitude),
      lng: Number(lead.longitude),
    };
    bounds.extend(position);
    hasBounds = true;

    const marker = new window.google.maps.Marker({
      map,
      position,
      title: lead.name || '',
      label: String(index + 1),
    });
    marker.addListener('click', () => emit('selectLead', lead));
    markers.push(marker);
  });

  if (center && Number(props.radius || 0) > 0) {
    circle = new window.google.maps.Circle({
      map,
      center,
      radius: Number(props.radius),
      fillColor: '#1f93ff',
      fillOpacity: 0.12,
      strokeColor: '#1f93ff',
      strokeOpacity: 0.7,
      strokeWeight: 2,
    });
    const circleBounds = circle.getBounds();
    if (circleBounds) {
      bounds.extend(circleBounds.getNorthEast());
      bounds.extend(circleBounds.getSouthWest());
    }
    hasBounds = true;
  }

  if (hasBounds) {
    map.fitBounds(bounds, 40);
  } else {
    map.setCenter(fallbackCenter);
    map.setZoom(12);
  }
};

onMounted(async () => {
  if (!props.apiKey) return;

  try {
    await loadGoogleMaps(props.apiKey);
    isReady.value = true;
    await renderMap();
  } catch {
    loadError.value = t('PROSPECTING.SEARCH.MAP_LOAD_ERROR');
  }
});

watch(
  () => [props.apiKey, props.center, props.radius, props.leads],
  async () => {
    if (!props.apiKey) return;
    if (!isReady.value) {
      try {
        await loadGoogleMaps(props.apiKey);
        isReady.value = true;
      } catch {
        loadError.value = t('PROSPECTING.SEARCH.MAP_LOAD_ERROR');
        return;
      }
    }
    await renderMap();
  },
  { deep: true }
);

onBeforeUnmount(() => {
  clearMarkers();
  clearCircle();
  map = null;
});
</script>

<template>
  <div
    v-if="!apiKey"
    class="flex items-center justify-center rounded-md border border-n-weak bg-n-solid-2 px-4 text-center text-sm text-n-slate-10"
    :class="heightClass"
  >
    {{ t('PROSPECTING.SEARCH.MAP_API_KEY_MISSING') }}
  </div>
  <div
    v-else-if="loadError"
    class="flex items-center justify-center rounded-md border border-n-weak bg-n-solid-2 px-4 text-center text-sm text-n-ruby-11"
    :class="heightClass"
  >
    {{ loadError }}
  </div>
  <div
    v-else
    ref="mapElement"
    class="overflow-hidden rounded-md border border-n-weak bg-n-solid-2"
    :class="heightClass"
  />
</template>
