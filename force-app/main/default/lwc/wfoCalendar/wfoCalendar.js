import { LightningElement, track } from 'lwc';
import findWfoDaysForAMonth from '@salesforce/apex/SAS_Month_Wfo_Finder.findWfoDaysForAMonth';
import getLoggedInEmployeeId from '@salesforce/apex/SAS_Employee_Controller.getLoggedInEmployeeId';

export default class WfoCalendar extends LightningElement {

    @track days = [];
    @track month;
    @track year;

    baseMonth;
    baseYear;

    empId;
    wfoMap = {};

    connectedCallback() {
        const today = new Date();

        this.month = today.getMonth();
        this.year = today.getFullYear();

        this.baseMonth = this.month;
        this.baseYear = this.year;

        getLoggedInEmployeeId()
            .then(emp => {
                this.empId = emp.Id;
                this.loadCalendar();
            })
            .catch(error => {
                console.error('Error fetching employee ID:', error);
            });
    }

    get monthLabel() {
        return new Date(this.year, this.month).toLocaleString('default', { month: 'long' });
    }

    loadCalendar() {
        const firstDay = new Date(this.year, this.month, 1);

        findWfoDaysForAMonth({
            empId: this.empId,
            inpDate: this.toApexDate(firstDay)
        })
        .then((data) => {
            this.wfoMap = data;
            this.generateDays();
        });
    }

    generateDays() {
        this.days = [];

        const firstDay = new Date(this.year, this.month, 1);
        const startingDayOfWeek = firstDay.getDay();
        const numDays = new Date(this.year, this.month + 1, 0).getDate();

        for (let i = 0; i < startingDayOfWeek; i++) {
            this.days.push({ date: `blank-${i}`, dayNumber: '', className: 'blank' });
        }

        for (let day = 1; day <= numDays; day++) {
            const jsDate = new Date(this.year, this.month, day);
            const apexDateStr = this.toApexDate(jsDate);

            const isWfo = this.wfoMap[apexDateStr] === true;

            this.days.push({
                date: apexDateStr,
                dayNumber: day,
                className: isWfo ? 'day red-day' : 'day'
            });
        }
    }

    handlePrevMonth() {
        if (!this.canGoPrev()) {
            return;
        }

        this.month--;
        if (this.month < 0) {
            this.month = 11;
            this.year--;
        }
        this.loadCalendar();
    }

    handleNextMonth() {
        if (!this.canGoNext()) {
            return;
        }

        this.month++;
        if (this.month > 11) {
            this.month = 0;
            this.year++;
        }
        this.loadCalendar();
    }

    canGoPrev() {
        const prev = new Date(this.year, this.month - 1);
        const base = new Date(this.baseYear, this.baseMonth - 1);
        return prev >= base;
    }

    canGoNext() {
        const next = new Date(this.year, this.month + 1);
        const base = new Date(this.baseYear, this.baseMonth + 1);
        return next <= base;
    }

    toApexDate(jsDate) {
        const yyyy = jsDate.getFullYear();
        const mm = String(jsDate.getMonth() + 1).padStart(2, '0');
        const dd = String(jsDate.getDate()).padStart(2, '0');
        return `${yyyy}-${mm}-${dd}`;
    }
}
