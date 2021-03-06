<template>
  <v-container>
    <v-layout>
      <v-flex class="text-center" xs12 md6 offset-md3>
        <h1 class="title font-weight-bold">
          Patch Me: Eye Patch Tracking Report
        </h1>
        <p class="subtitle-1">
          Enter the record key below to create the report to share with your
          provider
        </p>
      </v-flex>
    </v-layout>

    <v-form ref="form">
      <v-layout row wrap justify-center>
        <v-flex xs10 md3>
          <v-text-field label="Record Key" v-model="recordKey"></v-text-field>
          <v-select
            :items="reportDays"
            label="Number of Days"
            :value="numberOfDays"
            v-model="numberOfDays"
          ></v-select>
        </v-flex>
      </v-layout>

      <v-layout row wrap justify-center>
        <v-flex xs10 md3>
          <v-btn
            block
            class="primary"
            @click="createReport"
            :disabled="!recordKey"
            >Show Report</v-btn
          >
        </v-flex>
      </v-layout>
    </v-form>
    <v-layout v-if="records">
      <v-flex class="text-center pt-9" hidden-sm-and-down>
        <h1 class="title font-weight-bold">
          Patching Report for Last {{ numberOfDays }} days
        </h1>
        <pure-vue-chart
          :points="points"
          :width="800"
          :height="200"
          :show-y-axis="true"
          :show-x-axis="true"
          :show-values="true"
          :show-trend-line="true"
          :trend-line-width="2"
          trend-line-color="lightblue"
        />
      </v-flex>
      <v-flex class="text-center pt-9" hidden-md-and-up>
        <h1 class="title font-weight-bold">
          Patching Report for Last {{ numberOfDays }} days
        </h1>
        <pure-vue-chart
          :points="points"
          :width="600"
          :height="200"
          :show-y-axis="true"
          :show-x-axis="true"
          :show-values="true"
          :show-trend-line="true"
          :trend-line-width="2"
          trend-line-color="lightblue"
          class="hidden-xs-only"
        />
        <pure-vue-chart
          :points="points"
          :width="300"
          :height="200"
          :show-y-axis="true"
          :show-x-axis="false"
          :show-values="false"
          :show-trend-line="true"
          :trend-line-width="2"
          trend-line-color="lightblue"
          class="hidden-sm-and-up"
        />
      </v-flex>
    </v-layout>
    <v-layout v-if="records">
      <v-flex class="text-center pt-9" xs12 md8 offset-md2>
        <h2 class="title">
          Average Minutes Patched per Day (Only on Days Patched):
          {{ averageTimePatchedPerDay }}
        </h2>
        <h2 class="title">
          Average Minutes Patched per Day (All {{ numberOfDays }} days):
          {{ averageTimePatchedPerDayOverAllDays }}
        </h2>
      </v-flex>
    </v-layout>
  </v-container>
</template>

<script>
import { db } from '../scripts/db';
import moment from 'moment';
import PureVueChart from 'pure-vue-chart';

export default {
  components: {
    PureVueChart
  },
  created() {
    if (this.$route.query.id) {
      this.recordKey = this.$route.query.id;
    }
  },
  data() {
    return {
      recordKey: '',
      points: [],
      reportDays: [
        { text: '30 days', value: 30 },
        { text: '60 days', value: 60 }
      ],
      numberOfDays: 30,
      numberOfDaysPatched: 0,
      averageTimePatchedPerDay: undefined,
      averageTimePatchedPerDayOverAllDays: undefined,
      records: undefined
    };
  },
  methods: {
    createReport: async function() {
      var documentSnapshot = await db
        .collection('users')
        .doc(this.recordKey)
        .get();
      if (documentSnapshot.exists) {
        var document = documentSnapshot.data();
        this.records = document.data;
        this.points.length = 0;
        this.numberOfDaysPatched = 0;
        var totalPatchTime = 0;
        for (var i = this.numberOfDays - 1; i >= 0; i--) {
          var date = moment()
            .subtract(i, 'days')
            .format('M/D/YYYY');
          var record = this.records.find(v => v['date'] === date);
          if (record) {
            totalPatchTime += record['minutes'];
            this.points.push(record['minutes']);
            this.numberOfDaysPatched++;
          } else {
            this.points.push(0);
          }
        }
        this.averageTimePatchedPerDay = Math.floor(
          totalPatchTime / this.numberOfDaysPatched
        );
        this.averageTimePatchedPerDayOverAllDays = Math.floor(
          totalPatchTime / this.numberOfDays
        );
      } else {
        this.records = undefined;
        alert(
          'Record key not found. Please enter a valid record key and try again.'
        );
      }
    }
  }
};
</script>

<style scoped>
.v-calendar .v-event {
  font-size: 30px;
}
</style>
