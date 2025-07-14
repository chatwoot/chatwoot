import { createRouter, createWebHashHistory } from 'vue-router'

import i18n from './i18n'
import RouterComponent from './views/Router'
import DocumentComponent from './views/Document'
import ExampleComponent from './views/Example'

import FullExampleComponent from './views/examples/Full'
import SimpleExampleComponent from './views/examples/Simple'
import AvatarExampleComponent from './views/examples/Avatar'
import DragExampleComponent from './views/examples/Drag'
import MultipleExampleComponent from './views/examples/Multiple'
import ChunkExampleComponent from './views/examples/Chunk'
import VuexExampleComponent from './views/examples/Vuex'
import TypescriptExampleComponent from './views/examples/Typescript'
import AsyncEventsExampleComponent from './views/examples/AsyncEvents'


// console.log(i18n)


let examples = [{
    path: '',
    component: FullExampleComponent,
  },
  {
    path: 'full',
    component: FullExampleComponent,
  },
  {
    path: '',
    component: SimpleExampleComponent,
  },
  {
    path: 'simple',
    component: SimpleExampleComponent,
  },
  {
    path: 'avatar',
    component: AvatarExampleComponent,
  },
  {
    path: 'drag',
    component: DragExampleComponent,
  },
  {
    path: 'multiple',
    component: MultipleExampleComponent,
  },
  {
    path: 'chunk',
    component: ChunkExampleComponent,
  },
  {
    path: 'vuex',
    component: VuexExampleComponent,
  },
  {
    path: 'typescript',
    component: TypescriptExampleComponent,
  },
  {
    path: 'asyncevents',
    component: AsyncEventsExampleComponent,
  },
]


const router = createRouter({
  history: createWebHashHistory(),
  scrollBehavior(to, from, savedPosition) {
    if (savedPosition) {
      return savedPosition
    } else if (to.hash) {
      return { el: to.hash, top: document.querySelector('#header').offsetHeight }
    } else {
      return { x: 0, y: 0 }
    }
  },
  routes: [{
    path: '/:locale(' + i18n.global.availableLocales.join('|') + ')?',
    component: RouterComponent,
    children: [{
        path: 'documents',
        component: DocumentComponent,
      },
      {
        path: 'examples',
        component: ExampleComponent,
        children: examples,
      },
      {
        path: '',
        component: ExampleComponent,
        children: examples,
      },
    ]
  }, ]
})
export default router