// The avatar needs WebGL2 on real graphics hardware. Checking first avoids downloading it where it can't render.
export const supportsCaptainAvatar = () => {
  try {
    const gl = document.createElement('canvas').getContext('webgl2', {
      failIfMajorPerformanceCaveat: true,
    });
    gl?.getExtension('WEBGL_lose_context')?.loseContext();
    return !!gl;
  } catch {
    return false;
  }
};
