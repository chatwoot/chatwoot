const stub = { name: 'StubbedComponent', render: () => null }

export function autoStubComponents (vnodes: any[]) {
  for (const vnode of vnodes) {
    if (typeof vnode.type === 'object' && (vnode.type as any).name !== 'HistoireVariant') {
      vnode.type = stub
    }
    if (Array.isArray(vnode.children)) {
      autoStubComponents(vnode.children)
    }
  }
}
