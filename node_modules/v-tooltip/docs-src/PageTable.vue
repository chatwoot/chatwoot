<template>
  <table>
    <thead>
      <th v-for="(header, index) of tableHeaders" :key="index">{{ header }}</th>
    </thead>
    <tbody>
      <tr v-for="(row, index) of tableData" :key="index">
        <td
          v-for="(data, i) of row"
          :key="i"
          v-tooltip="{
            content: data,
            delay: 0,
            classes: ['no-transition']
          }"
        >
          {{ data }}
        </td>
      </tr>
    </tbody>
  </table>
</template>

<script>
import faker from 'faker'

let rows = 10
let cols = 10
let tableHeaders = Array.from({ length: cols }).map(
  i => faker.random.word().toLowerCase()
)

let getTableData = () => Array.from({ length: rows }).map(i => {
  let date = new Date(faker.date.past())
  return [
    i,
    faker.address.city(),
    faker.company.companyName(),
    faker.date.month(),
    date.getYear() + 1900,
    faker.address.country(),
    faker.hacker.noun(),
    faker.random.number(),
    faker.random.number(),
    faker.random.word(),
  ]
})

export default {
  data () {
    return {
      tableHeaders,
      tableData: getTableData(),
    }
  },
}
</script>

<style scoped>
table, tr, th, td {
  padding: 5px;
  border-collapse: collapse;
  border: 0px;
}

thead, th {
  border-bottom: 1px solid #505050;
  background-color: #585858;
  color: #f8f8f8;
}

tr:nth-child(even) {
  background-color: #e6e6e6;
}
tr:nth-child(odd) {
  background-color: #f8f8f8;
}
</style>

