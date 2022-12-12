const acceptValue = ['input','textarea','option','select']
module.exports = (tag, type, attr) => {
  return (
    (attr === 'value' && acceptValue.includes(tag)) && type !== 'button' ||
    (attr === 'selected' && tag === 'option') ||
    (attr === 'checked' && tag === 'input') ||
    (attr === 'muted' && tag === 'video')
  )
}
