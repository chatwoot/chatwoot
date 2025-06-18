import Quill from 'quill';

const Block = Quill.import('blots/block');

class StyledBlock extends Block {
  static create(value) {
    let node = super.create(value);
    node.setAttribute('style', 'margin:0; padding:0');
    return node;
  }
}

StyledBlock.blotName = 'block';
StyledBlock.tagName = 'p';

export default StyledBlock;
