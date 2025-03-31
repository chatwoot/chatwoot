export const createSuccess = (body: any, overrides: Partial<Response> = {}) => {
  return Promise.resolve({
    json: () => Promise.resolve(body),
    ok: true,
    status: 200,
    statusText: 'OK',
    ...overrides,
  }) as Promise<Response>
}

export const createError = (overrides: Partial<Response> = {}) => {
  return Promise.resolve({
    ok: false,
    status: 404,
    statusText: 'Not Found',
    ...overrides,
  }) as Promise<Response>
}
