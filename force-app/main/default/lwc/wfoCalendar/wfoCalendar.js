import { LightningElement, track } from 'lwc';
import getWfoDays from '@salesforce/apex/WfoFinderMonthController.getWfoDays';
import getLoggedInEmployeeId from '@salesforce/apex/SAS_Employee_Controller.getLoggedInEmployeeId';

export default class WfoCalendar extends LightningElement {

    @track days = [];
    @track month;
    @track year;
    wfoMap = {};

    connectedCallback() {
        const today = new Date();
        this.month = today.getMonth();
        this.year = today.getFullYear();
        this.loadCalendar();

        getLoggedInEmployeeId()
        .then(emp => {
            this.empId = emp.Id; // ✅ extract Id
            console.log('Logged in Employee ID:', this.empId);
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
        const empId = this.empId; // Replace or make @api
        console.log(this.toApexDate(firstDay));
        getWfoDays({ empId: empId, dateValue: this.toApexDate(firstDay) })
            .then((data) => {
                this.wfoMap = data;
                this.generateDays();
            });
    }

    generateDays() {
        this.days = [];

        const firstDay = new Date(this.year, this.month, 1);
        console.log(firstDay);
        const startingDayOfWeek = firstDay.getDay();
        const numDays = new Date(this.year, this.month + 1, 0).getDate();

        for (let i = 0; i < startingDayOfWeek; i++) {
            this.days.push({ date: `blank-${i}`, dayNumber: '', className: 'blank' });
        }

        for (let day = 1; day <= numDays; day++) {
            const jsDate = new Date(this.year, this.month, day);
            const apexDateStr = this.toApexDate(jsDate);
            console.log(apexDateStr);

            const isWfo = this.wfoMap[apexDateStr] === true;

            this.days.push({
                date: apexDateStr,
                dayNumber: day,
                className: isWfo ? 'day red-day' : 'day'
            });
        }
    }

    handlePrevMonth() {
        this.month--;
        if (this.month < 0) {
            this.month = 11;
            this.year--;
        }
        this.loadCalendar();
    }

    handleNextMonth() {
        this.month++;
        if (this.month > 11) {
            this.month = 0;
            this.year++;
        }
        this.loadCalendar();
    }

    toApexDate(jsDate) {
    const yyyy = jsDate.getFullYear();
    const mm = String(jsDate.getMonth() + 1).padStart(2, '0');
    const dd = String(jsDate.getDate()).padStart(2, '0');
    return `${yyyy}-${mm}-${dd}`;
}

}
