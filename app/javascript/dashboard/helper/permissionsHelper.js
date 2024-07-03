export const hasPermissions = (
  requiredPermissions = [],
  availablePermissions = []
) => {
  return requiredPermissions.some(permission =>
    availablePermissions.includes(permission)
  );
};

export const buildPermissionsFromRouter = (routes = []) =>
  routes.reduce((acc, route) => {
    if (route.name) {
      if (!route.meta || !route.meta.permissions) {
        // eslint-disable-next-line
        console.error(route);
        throw new Error(
          "The route doesn't have the required permissions defined"
        );
      }
      acc[route.name] = route.meta.permissions;
    }

    if (route.children) {
      acc = {
        ...acc,
        ...buildPermissionsFromRouter(route.children),
      };
    }

    return acc;
  }, {});
