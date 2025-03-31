export const resolvedConfig = (ctx) => {
    let js = `export const config = ${JSON.stringify(ctx.config)}\n`;
    if (ctx.config.theme?.logo) {
        for (const key in ctx.config.theme.logo) {
            js += `import Logo_${key} from '${ctx.config.theme.logo[key]}'\n`;
        }
    }
    js += `export const logos = {${Object.keys(ctx.config.theme?.logo ?? {}).map(key => `${key}: Logo_${key}`).join(', ')}}\n`;
    return js;
};
