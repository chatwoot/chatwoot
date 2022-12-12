# Turning violation nodes into readable HTML

The violations returns a list of rules that had failures. Each rule has a list of nodes that failed the rule. Each node may have failed for one or more reasons. This information is encoded in a set of structures that can be somewhat difficult to comprehend. This code shows how to turn a list of violations into a table and then for each node in a rule's nodes list, how to generate a summary of the reason(s) that rule failed.

The example uses handlebars templates but can be easily adapted to other formats

## The JavaScript

```js
function helperItemIterator(items, template) {
  var out = '';
  if (items) {
    for (var i = 0; i < items.length; i++) {
      out += template(items[i]);
    }
  }
  return out;
}
Handlebars.registerHelper('violations', function(items) {
  return helperItemIterator(items, compiledRowTemplate);
});
Handlebars.registerHelper('related', function(items) {
  return helperItemIterator(items, compiledRelatedNodeTemplate);
});
Handlebars.registerHelper('reasons', function(items) {
  return helperItemIterator(items, compiledFailureTemplate);
});

// Setup handlebars templates

compiledRowTemplate = Handlebars.compile(rowTemplate.innerHTML);
compiledTableTemplate = Handlebars.compile(tableTemplate.innerHTML);
compiledRelatedListTemplate = Handlebars.compile(relatedListTemplate.innerHTML);
compiledRelatedNodeTemplate = Handlebars.compile(relatedNodeTemplate.innerHTML);
compiledFailureTemplate = Handlebars.compile(failureTemplate.innerHTML);
compiledReasonsTemplate = Handlebars.compile(reasonsTemplate.innerHTML);

function messageFromRelatedNodes(relatedNodes) {
  var retVal = '';
  if (relatedNodes.length) {
    var list = relatedNodes.map(function(node) {
      return {
        targetArrayString: JSON.stringify(node.target),
        targetString: node.target.join(' ')
      };
    });
    retVal += compiledRelatedListTemplate({ relatedNodeList: list });
  }
  return retVal;
}

function messagesFromArray(nodes) {
  var list = nodes.map(function(failure) {
    return {
      message: failure.message.replace(/</gi, '&lt;').replace(/>/gi, '&gt;'),
      relatedNodesMessage: messageFromRelatedNodes(failure.relatedNodes)
    };
  });
  return compiledReasonsTemplate({ reasonsList: list });
}

function summary(node) {
  var retVal = '';
  if (node.any.length) {
    retVal += '<h3 class="error-title">Fix any of the following</h3>';
    retVal += messagesFromArray(node.any);
  }

  var all = node.all.concat(node.none);
  if (all.length) {
    retVal += '<h3 class="error-title">Fix all of the following</h3>';
    retVal += messagesFromArray(all);
  }
  return retVal;
}

/*
 * This code will generate a table of the rules that failed including counts and links to the Deque University help
 * for each rule.
 *
 * When used, you should attach click handlers to the anchors in order to generate the details for each of the
 * violations for each rule.
 */

if (results.violations.length) {
  var violations = results.violations.map(function(rule, i) {
    return {
      impact: rule.impact,
      help: rule.help.replace(/</gi, '&lt;').replace(/>/gi, '&gt;'),
      bestpractice: rule.tags.indexOf('best-practice') !== -1,
      helpUrl: rule.helpUrl,
      count: rule.nodes.length,
      index: i
    };
  });

  html = compiledTableTemplate({ violationList: violations });
}

/*
 * To generate the human readable summary, call the `summary` function with the node. This will return HTML for that node.
 */

reasonHtml = summary(node);
```

## The Handlebars Templates

```handlebars
<script id="rowTemplate" type="text/x-handlebars-template">
<tr>
  <th scope="row" class="help">
    <a href="javascript:;" class="rule" data-index="{{index}}">
      {{{help}}}
    </a>
  </th>
  <td scope="row">
    <a target="_blank" href="{{helpUrl}}">?</a>
  </td>
  <td class="count">
    {{count}}
  </td>
  <td class="impact">
    {{impact}}
  </td>
</tr>
</script>
<script id="tableTemplate" type="text/x-handlebars-template">
<table>
  <tr>
  <th scope="col">Description</th>
  <th scope="col">Info</th>
  <th scope="col">Count</th>
  <th scope="col">Impact</th>
  </tr>
  {{#violations violationList}}{{/violations}}
</table>
</script>
<script id="relatedListTemplate" type="text/x-handlebars-template">
<ul>Related Nodes:
  {{#related relatedNodeList}}{{/related}}
</ul>
</script>
<script id="relatedNodeTemplate" type="text/x-handlebars-template">
<li>
  <a href="javascript:;" class="related-node" data-element="{{targetArrayString}}">
    {{targetString}}
  </a>
</li>
</script>
<script id="reasonsTemplate" type="text/x-handlebars-template">
<p class="summary">
  <ul class="failure-message">
    {{#reasons reasonsList}}{{/reasons}}
  </ul>
</p>
</script>
<script id="failureTemplate" type="text/x-handlebars-template">
<li>
  {{message}}
  {{{relatedNodesMessage}}}
</li>
</script>
```
