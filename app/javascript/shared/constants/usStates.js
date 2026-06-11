import iso3166 from 'iso-3166-2';

const usSubdivisions = iso3166.country('US')?.sub ?? {};

const usStates = Object.entries(usSubdivisions)
  .map(([code, sub]) => ({ id: code.replace(/^US-/, ''), name: sub.name }))
  .sort((a, b) => a.name.localeCompare(b.name));

export default usStates;
