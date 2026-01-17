export default {
    title: 'Vanilla story',
    icon: 'ion:logo-nodejs',
    variants: [
        {
            title: 'Hello',
            onMount: ({ el, state, onUpdate }) => {
                state.count = 0;
                const div = document.createElement('div');
                div.innerHTML = '<h1>Hello World</h1>';
                el.appendChild(div);
                const counter = document.createElement('pre');
                counter.innerHTML = `Counter: ${state.counter}`;
                div.appendChild(counter);
                onUpdate(() => {
                    counter.innerHTML = `Counter: ${state.count}`;
                });
            },
            onMountControls: ({ el, state, onUnmount }) => {
                const add = () => {
                    state.count++;
                };
                Object.assign(el.style, {
                    padding: '8px',
                });
                const btn = document.createElement('button');
                btn.innerHTML = '+1';
                Object.assign(btn.style, {
                    padding: '6px',
                    borderRadius: '3px',
                    backgroundColor: '#a7f3d0',
                });
                btn.addEventListener('click', add);
                el.appendChild(btn);
                onUnmount(() => {
                    btn.removeEventListener('click', add);
                });
            },
        },
        {
            title: 'Meow',
            onMount: ({ el, onUpdate, onUnmount }) => {
                const div = document.createElement('div');
                div.innerHTML = '<h1>Meow</h1>';
                el.appendChild(div);
                onUpdate(() => {
                    console.log('update');
                });
                onUnmount(() => {
                    el.removeChild(div);
                });
            },
        },
    ],
};
