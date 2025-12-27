import { LightningElement } from 'lwc';

export default class Calendar extends LightningElement {
    weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    monthName;
    year;
    days = [];

    connectedCallback() {
        const today = new Date();
        const month = today.getMonth();
        const year = today.getFullYear();

        this.monthName = today.toLocaleString('default', { month: 'long' });
        this.year = year;

        this.buildCalendar(month, year);
    }

    buildCalendar(month, year) {
        const firstDay = new Date(year, month, 1).getDay();
        const totalDays = new Date(year, month + 1, 0).getDate();

        let calendarDays = [];

        // Add blank cells before the 1st day
        for (let i = 0; i < firstDay; i++) {
            calendarDays.push({
                key: 'blank-' + i,
                label: '',
                className: 'day blank'
            });
        }

        // Add month days
        for (let d = 1; d <= totalDays; d++) {
            calendarDays.push({
                key: 'day-' + d,
                label: d,
                className: 'day'
            });
        }

        this.days = calendarDays;
    }
}
