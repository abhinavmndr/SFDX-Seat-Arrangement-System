import { LightningElement, track } from 'lwc';
import getEmployeesByName from '@salesforce/apex/SAS_Employee_Controller.getEmployeesByName';

export default class EmployeeSearch extends LightningElement {
    @track employees = [];
    searchKey = '';
    isDropdownOpen = false;
    isLoading = false;
    delayTimeout;

    get hasResults() {
        return this.employees.length > 0;
    }

    handleChange(event) {
        this.searchKey = event.target.value;
        window.clearTimeout(this.delayTimeout);

        if (this.searchKey.length < 2) {
            this.employees = [];
            return;
        }

        this.delayTimeout = setTimeout(() => {
            this.searchEmployees();
        }, 300);
    }

    searchEmployees() {
        this.isLoading = true;

        getEmployeesByName({ empName: this.searchKey })
            .then(result => {
                // 🔐 Normalize null values safely
                this.employees = result.map(emp => ({
                    ...emp,
                    blockName: emp.Block__r ? emp.Block__r.Name : 'N/A',
                    groupName: emp.Group__c ? emp.Group__c : 'N/A',
                    blockLabel: 'Block: ' + (emp.Block__r ? emp.Block__r.Name : 'N/A'),
                    groupLabel: 'Group: ' + (emp.Group__c ? emp.Group__c : 'N/A')
                }));
            })
            .catch(error => {
                console.error(error);
                this.employees = [];
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    openDropdown() {
        this.isDropdownOpen = true;
    }

    closeDropdown() {
        setTimeout(() => {
            this.isDropdownOpen = false;
        }, 200);
    }

    handleSelect(event) {
        const selectedId = event.currentTarget.dataset.id;
        const selectedEmployee = this.employees.find(e => e.Id === selectedId);

        this.searchKey = selectedEmployee.Name;
        this.isDropdownOpen = false;

        this.dispatchEvent(
            new CustomEvent('employeeselected', {
                detail: selectedEmployee
            })
        );
    }
}
