<a name="3.0.2"></a>

## [3.0.2](https://github.com/mengxiong10/vue2-datepicker/compare/v3.0.1...v3.0.2) (2019-11-14)

### 修复 Bug

- 兼容旧版 vue 的`inject`语法 ([c03632f](https://github.com/mengxiong10/vue2-datepicker/commit/c03632f))
- 应该返回 `[null, null]` 当清除范围的时候 ([635631f](https://github.com/mengxiong10/vue2-datepicker/commit/635631f))
- 当年在 0 到 100 时候显示问题 ([8c546cc](https://github.com/mengxiong10/vue2-datepicker/commit/8c546cc))

### 新功能

- 添加属性 `partial-update`, 选择年或月的时候也更新日期 ([07f4271](https://github.com/mengxiong10/vue2-datepicker/commit/07f4271))

<a name="3.0.1"></a>

## [3.0.1](https://github.com/mengxiong10/vue2-datepicker/compare/v3.0.0...v3.0.1) (2019-11-11)

### 修复 Bug

- 修复清除事件没有触发 ([#369](https://github.com/mengxiong10/vue2-datepicker/issues/369)) ([06e158e](https://github.com/mengxiong10/vue2-datepicker/commit/06e158e))
- ie 兼容性 ([99a4abd](https://github.com/mengxiong10/vue2-datepicker/commit/99a4abd))

<a name="3.0.0"></a>

# [3.0.0](https://github.com/mengxiong10/vue2-datepicker/compare/v3.0.0-beta.1...v3.0.0) (2019-11-10)

### 修复 bug

- 修复国际化没有应用到日期的格式

### 新功能

- 添加星期选择
  ```html
  <date-picer type="week" />
  ```
- 添加内联模式, 没有输入框

  ```html
  <date-picker inline />
  ```

- 添加 `open` 控制弹窗的状态
- 添加 am/pm 的选择, 当使用 12 小时制
- 添加事件`open`和`close`
- 添加 `hourStep`/`minuteStep`/`secondStep`/`showHour`/`showMinute`/`showSecond`/`use12h` 对时间选择更多的控制

### 不兼容更新

- 需要单独引入样式
- 修改默认语音是英文, 可以自行引入语言包
- 日期范围选择重构, 现在模式是可以在一个日历上面选择范围, 每次选择需要点击 2 次.
- 修改 slot `calendar-icon` 为 `icon-calendar`.
- `appendToBody` 默认值修改为 true.
- 移除 `not-before` 和 `not-after`, 用 `disabledDate` 代替.

  ```html
  <template>
    <date-picker :disabled-date="notBeforeToday"></date-picker>
    <date-picker :disabled-date="notAfterToday"></date-picker>
  </template>
  <script>
    export default {
      methods: {
        notBeforeToday(date) {
          const today = new Date();
          today.setHours(0, 0, 0, 0);
          return date.getTime() < today.getTime();
        },
        notAfterToday(date) {
          const today = new Date();
          today.setHours(0, 0, 0, 0);
          return date.getTime() > today.getTime();
        },
      },
    };
  </script>
  ```

- 移除`width`, 用 `style="{ width: "" }"` 代替.
- 修改 `shortcuts` , onClick 函数返回一个日期.
- 移除`firstDayOfWeek`到语言包

## [2.13.3](https://github.com/mengxiong10/vue2-datepicker/compare/v2.13.2...v2.13.3) (2019-10-29)

### 修复 Bug

- 修复`defaultValue`的变化应该修改日历显示 ([#364](https://github.com/mengxiong10/vue2-datepicker/issues/364)) ([5e463bd](https://github.com/mengxiong10/vue2-datepicker/commit/5e463bd3cf973b5257a58810f980c46e26824426))

## [2.13.2](https://github.com/mengxiong10/vue2-datepicker/compare/v2.13.1...v2.13.2) (2019-10-23)

### 修复 Bug

- 兼容移动端点击事件 ([#334](https://github.com/mengxiong10/vue2-datepicker/issues/334)) ([57d57fc](https://github.com/mengxiong10/vue2-datepicker/commit/57d57fc645d670e88c60141d2238066c2ed1ce8f))
- 修复`ro`语言 ([43c59e6](https://github.com/mengxiong10/vue2-datepicker/commit/43c59e6b40ac71dd9ea988d0b51269e99dff7b22))

## [2.13.1](https://github.com/mengxiong10/vue2-datepicker/compare/v2.13.0...v2.13.1) (2019-10-22)

### 修复 Bug

- 修复西班牙语错误 ([#361](https://github.com/mengxiong10/vue2-datepicker/issues/361)) ([04e1032](https://github.com/mengxiong10/vue2-datepicker/commit/04e10328eabfac6e10fe4a49e7579f2eff7a1736))

# [2.13.0](https://github.com/mengxiong10/vue2-datepicker/compare/v2.12.0...v2.13.0) (2019-10-14)

### 修复 Bug

- 移除键盘事件的阻止冒泡 ([864ab83](https://github.com/mengxiong10/vue2-datepicker/commit/864ab835ca93322eb103fa1e00770976b7d95c41))
- 修复 clickoutside 有时无效的问题 ([#326](https://github.com/mengxiong10/vue2-datepicker/issues/326)) ([d9619f8](https://github.com/mengxiong10/vue2-datepicker/commit/d9619f815c6a87052b353b800c7e597a8dea816a))

### 新功能

- 添加属性 `icon-day` 去选择日历图标的文字 ([62c3d60](https://github.com/mengxiong10/vue2-datepicker/commit/62c3d60dd93c15a3c3c8d433836f3bb364d30bb7))

# [2.12.0](https://github.com/mengxiong10/vue2-datepicker/compare/v2.11.2...v2.12.0) (2019-06-25)

### 新功能

- 添加属性 `time-select-options` ([#227](https://github.com/mengxiong10/vue2-datepicker/issues/227)) ([a55b4b6](https://github.com/mengxiong10/vue2-datepicker/commit/a55b4b6))

## [2.11.2](https://github.com/mengxiong10/vue2-datepicker/compare/v2.11.1...v2.11.2) (2019-05-15)

### 修复 Bug

- 移除最后一个快捷选项的 "|" ([c6a6300](https://github.com/mengxiong10/vue2-datepicker/commit/c6a6300))
- 修复测试由于时区失败的问题 ([#300](https://github.com/mengxiong10/vue2-datepicker/issues/300)) ([ec69590](https://github.com/mengxiong10/vue2-datepicker/commit/ec69590))

## [2.11.1](https://github.com/mengxiong10/vue2-datepicker/compare/v2.11.0...v2.11.1) (2019-04-30)

### 修复 Bug

- 关闭弹窗当选择快捷方式的时候 ([5823f85](https://github.com/mengxiong10/vue2-datepicker/commit/5823f85))

# [2.11.0](https://github.com/mengxiong10/vue2-datepicker/compare/v2.10.3...v2.11.0) (2019-04-09)

### 修复 Bug

- 修复 `clickoutside` 失效 ([#291](https://github.com/mengxiong10/vue2-datepicker/issues/291)) ([9bb6046](https://github.com/mengxiong10/vue2-datepicker/commit/9bb6046))

### 新功能

- 添加事件 `select-year` 和 `select-month` ([#290](https://github.com/mengxiong10/vue2-datepicker/issues/290)) ([20d1f19](https://github.com/mengxiong10/vue2-datepicker/commit/20d1f19))

## [2.10.3](https://github.com/mengxiong10/vue2-datepicker/compare/v2.10.2...v2.10.3) (2019-03-14)

### 修复 Bug

- 修复手动输入不会改变值 ([#266](https://github.com/mengxiong10/vue2-datepicker/issues/266)) ([aa20a1e](https://github.com/mengxiong10/vue2-datepicker/commit/aa20a1e))

## [2.10.2](https://github.com/mengxiong10/vue2-datepicker/compare/v2.10.1...v2.10.2) (2019-03-14)

### 修复 Bug

- 修复选择分钟会影响小时的问题 ([#168](https://github.com/mengxiong10/vue2-datepicker/issues/168)) ([2afed88](https://github.com/mengxiong10/vue2-datepicker/commit/2afed88))
- 移除输入框后缀的样式 ([e7775d6](https://github.com/mengxiong10/vue2-datepicker/commit/e7775d6))

### Performance Improvements

- 移除 IE10 的默认清除样式([6a990d8](https://github.com/mengxiong10/vue2-datepicker/commit/6a990d8))

# [2.10.0](https://github.com/mengxiong10/vue2-datepicker/compare/v2.9.2...v2.10.0) (2019-02-12)

### 新功能

- 添加属性 default-value 作为打开日历的默认时间 ([#94](https://github.com/mengxiong10/vue2-datepicker/issues/94)) ([4ff6945](https://github.com/mengxiong10/vue2-datepicker/commit/4ff6945))
- 输入框有焦点的时候自动打开日历选择, 失去焦点时关闭 ([3bcedf5](https://github.com/mengxiong10/vue2-datepicker/commit/3bcedf5))

## [2.9.2](https://github.com/mengxiong10/vue2-datepicker/compare/v2.9.1...v2.9.2) (2019-02-10)

### 修复 Bug

- 选择年的面板的标题显示错误 ([#245](https://github.com/mengxiong10/vue2-datepicker/issues/245)) ([7bc2785](https://github.com/mengxiong10/vue2-datepicker/commit/7bc2785))

## [2.9.1](https://github.com/mengxiong10/vue2-datepicker/compare/v2.9.0...v2.9.1) (2019-02-01)

### 修复 Bug

- 修复当绑定的值是 null 时格式化字符串返回的时间错误 ([#244](https://github.com/mengxiong10/vue2-datepicker/issues/244)) ([92243ab](https://github.com/mengxiong10/vue2-datepicker/commit/92243ab))

# [2.9.0](https://github.com/mengxiong10/vue2-datepicker/compare/v2.8.1...v2.9.0) (2019-01-29)

### 新功能

- 支持自定义格式化函数 ([c801516](https://github.com/mengxiong10/vue2-datepicker/commit/c801516))

## [2.8.1](https://github.com/mengxiong10/vue2-datepicker/compare/v2.8.0...v2.8.1) (2019-01-24)

### 修复 Bug

- 点击外部关闭监听的函数从捕获改成冒泡, 可以用 stopPropagation 阻止关闭 ([054758e](https://github.com/mengxiong10/vue2-datepicker/commit/054758e))

# [2.8.0](https://github.com/mengxiong10/vue2-datepicker/compare/v2.7.0...v2.8.0) (2019-01-13)

### 新功能

- 添加属性 `valueType` 格式化绑定值 ([dd6f2ea](https://github.com/mengxiong10/vue2-datepicker/commit/dd6f2ea))

| 可选值    | 描述                                     |
| --------- | ---------------------------------------- |
| date      | 返回的绑定值是 Date 对象                 |
| timestamp | 返回的绑定值是时间戳数字                 |
| format    | 返回的绑定值是通过`format`属性格式化的值 |

# [2.7.0](https://github.com/mengxiong10/vue2-datepicker/compare/v2.6.3...v2.7.0) (2019-01-08)

### 新功能

- 在 mx-calendar 元素上添加 class 去表明现在的窗口类型(mx-clendar-panel-(year, date, time, month)) ([#219](https://github.com/mengxiong10/vue2-datepicker/issues/219)) ([1d0a67b](https://github.com/mengxiong10/vue2-datepicker/commit/1d0a67b))
- 添加新的属性 inputAttr 去自定义 input 的属性 ([2381089](https://github.com/mengxiong10/vue2-datepicker/commit/2381089))

## [2.6.4](https://github.com/mengxiong10/vue2-datepicker/compare/v2.6.3...v2.6.4) (2018-12-19)

### 修复 Bug

- 修复当手动清空输入框时间没有改变 ([39d2c40](https://github.com/mengxiong10/vue2-datepicker/commit/39d2c40))

## [2.6.3](https://github.com/mengxiong10/vue2-datepicker/compare/v2.6.2...v2.6.3) (2018-12-08)

### 修复 Bug

- 修复手动输入范围时无法成功的问题 ([#209](https://github.com/mengxiong10/vue2-datepicker/issues/209)) ([97289d1](https://github.com/mengxiong10/vue2-datepicker/commit/97289d1))

## [2.6.2](https://github.com/mengxiong10/vue2-datepicker/compare/v2.6.1...v2.6.2) (2018-10-30)

### 修复 Bug

- `calendar-change`事件在正确的时候触发 ([b1a5a41](https://github.com/mengxiong10/vue2-datepicker/commit/b1a5a41))

### 新功能

- 添加 `calendar-change` 事件 ([ef9314e](https://github.com/mengxiong10/vue2-datepicker/commit/ef9314e))

## [2.6.1](https://github.com/mengxiong10/vue2-datepicker/compare/v2.6.0...v2.6.1) (2018-10-17)

### 修复 Bug

- 阻止组件的事件冒泡到外面 ([de177d8](https://github.com/mengxiong10/vue2-datepicker/commit/de177d8))

### 新功能

- script 直接引用的时候自动注册组件 ([a310f59](https://github.com/mengxiong10/vue2-datepicker/commit/a310f59))

# [2.6.0](https://github.com/mengxiong10/vue2-datepicker/compare/v2.5.0...v2.6.0) (2018-10-11)

### 修复 Bug

- 修复快捷方式的颜色 ([ac4aa87](https://github.com/mengxiong10/vue2-datepicker/commit/ac4aa87))

### 新功能

- 添加属性 `appendToBody` ([e26e1f5](https://github.com/mengxiong10/vue2-datepicker/commit/e26e1f5))

# [2.5.0](https://github.com/mengxiong10/vue2-datepicker/compare/v2.4.3...v2.5.0) (2018-10-05)

### 新功能

- 添加 `panel-change` 事件 ([5cdba7b](https://github.com/mengxiong10/vue2-datepicker/commit/5cdba7b))

## [2.4.3](https://github.com/mengxiong10/vue2-datepicker/compare/v2.4.0...v2.4.3) (2018-09-28)

### 修复 Bug

- 修复选择时间时候显示'am', 'pm' ([8e475b3](https://github.com/mengxiong10/vue2-datepicker/commit/8e475b3))
- 修复一个 IE 兼容性问题 ([fefed17](https://github.com/mengxiong10/vue2-datepicker/commit/fefed17))
- 当选择一个时间的时候关闭面板 ([#154](https://github.com/mengxiong10/vue2-datepicker/issues/154)) ([12907ad](https://github.com/mengxiong10/vue2-datepicker/commit/12907ad))
- 修复年和月的禁用函数错误 ([#169](https://github.com/mengxiong10/vue2-datepicker/issues/169)) ([42bc068](https://github.com/mengxiong10/vue2-datepicker/commit/42bc068))

### 新功能

- 添加一个`clear`事件 ([e0776b6](https://github.com/mengxiong10/vue2-datepicker/commit/e0776b6))

<a name="2.4.0"></a>

# [2.4.0](https://github.com/mengxiong10/vue2-datepicker/compare/v2.3.2...v2.4.0) (2018-08-08)

### 新功能

- 添加属性`type`为`time`的时候只显示时间组件

## [2.3.2](https://github.com/mengxiong10/vue2-datepicker/compare/v2.2.0...v2.3.2) (2018-08-07)

### 新功能

- 添加属性 `date-format` 格式化时间组件头部和日期的 tooltip

# [2.2.0](https://github.com/mengxiong10/vue2-datepicker/compare/v2.1.0...v2.2.0) (2018-08-06)

### 修复 bug

- 设置 input 的 autocomplete 为 off 避免下拉框的干扰

### 新功能

- 添加时间'change-calendar-yeaer', 'change-calendar-month'方便联动两个窗口

# [2.1.0]() (2018-07-24)

### 新功能

- 添加`type` 支持月和年的单独选择

# [2.0.0]() (2018-06-16)

### 新功能

- 添加`clearable` 用于控制是否显示清除按钮
- 添加 slot `calendar-icon` 自定义日历图标
- 添加 slot `header` 和 `footer` 自定义弹出日历的头部和尾部
- `disabledDays` 现在支持函数

### 非兼容性更新

- 重构代码. 如果你自己 hack 过代码可能会失效
- `format` 默认值由 yyyy-MM-dd 改成 YYYY-MM-DD, 现在格式类似 moment.js. 不支持小写的 yyyy
- 移除了`custom-formatter`
- `editable` 默认由 false 改成 true, 现在日历范围也支持手动修改
- 当选择年或月的面板的时候不会修改日期(因为当设置了`not-before`或者`not-after`的时候会引发很多问题和 bug)
