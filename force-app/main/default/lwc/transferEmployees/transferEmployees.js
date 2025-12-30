import { LightningElement, wire, track } from 'lwc';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import EMPLOYEE_OBJECT from '@salesforce/schema/Employee__c';
import GROUP_FIELD from '@salesforce/schema/Employee__c.Group__c';
import { publish, MessageContext } from 'lightning/messageService';
import APPROVAL_REFRESH from '@salesforce/messageChannel/BlockSummaryRefresh__c';
import getTeams from '@salesforce/apex/SAS_Team_Controller.getTeams';
import getBlocks from '@salesforce/apex/SAS_Block_Controller.getBlocks';
import getEmployeesByTeam from '@salesforce/apex/SAS_Employee_Controller.getEmployeesByTeam';
import getEmployeesByName from '@salesforce/apex/SAS_Employee_Controller.getEmployeesByName';
import bulkUpdateEmployees from '@salesforce/apex/SAS_Employee_Controller.bulkUpdateEmployees';
import getAvailableSeats from '@salesforce/apex/SAS_Employee_Controller.getAvailableSeats';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class TransferEmployees extends LightningElement {

    activeFilter = null;
    @track groupOptions = [];
    allGroupOptions = [];
    @track blockOptions = [];
    allBlockOptions = [];
    @track employees = [];
    @track selectedEmployees = [];
    @track selectedRowIds = [];
    @track accumulatedSelectedEmployees = [];
    @track teamOptions = [];
    @track selectedTeam = '';
    selectedGroup = '';
    selectedBlock = null;
    isModalOpen = false;
    @track selectedFilterMethod = 'name';
    @track availableSeats = null;
    previousVisibleSelectedIds = new Set();
    @wire(MessageContext)
    messageContext;
    isLoading = false;
    
    filterOptions = [
        { label: 'Search by Name', value: 'name' },
        { label: 'Search by Team', value: 'team' }
    ];

    @track columns = [
        { label: 'Name', fieldName: 'Name' },
        { label: 'Email', fieldName: 'Email__c' },
        { label: 'Group', fieldName: 'Group__c' },
        { label: 'Block', fieldName: 'blockName' }
    ];

    connectedCallback() {

        getTeams()
            .then(data => {
                this.teamOptions = data.map(team => ({
                    label: team.Name,
                    value: team.Id
                }));
            })
            .catch(err => {
                console.error(err);
            });

        getBlocks()
            .then(data => {
                this.allBlockOptions = data.map(block => ({
                    label: block.Name,
                    value: block.Id
                }));
                this.blockOptions = [...this.allBlockOptions];
            })
            .catch(err => console.error(err));
    }

    get isUpdateDisabled() {
        return  (this.isNameFilter && this.accumulatedSelectedEmployees.length === 0) || (this.isTeamFilter && this.selectedEmployees.length === 0);
    }
    
    get isNameFilter() {
        return this.selectedFilterMethod === 'name';
    }

    get isTeamFilter() {
        return this.selectedFilterMethod === 'team';
    }

    get selectedEmployeeCount() {
        return this.isNameFilter
            ? this.accumulatedSelectedEmployees.length
            : this.selectedEmployees.length;
    }

    get isSeatInsufficient() {
        if (this.availableSeats === null || this.selectedEmployeeCount === 0) {
            return false;
        }
        return this.availableSeats < this.selectedEmployeeCount;
    }

    @wire(getObjectInfo, { objectApiName: EMPLOYEE_OBJECT })
    objectInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: GROUP_FIELD
    })
    picklistHandler({ data }) {
        if (data) {
            this.allGroupOptions = data.values;
            this.groupOptions = data.values;
        }
    }

    handleFilterMethodChange(event) {
        const previousFilter = this.selectedFilterMethod;
        this.selectedFilterMethod = event.detail.value;

        this.employees = [];
        this.selectedName = '';
        this.selectedTeam = '';
        this.selectedEmployees = [];
        this.selectedRowIds = [];

        if (previousFilter === 'name') {
            this.accumulatedSelectedEmployees = [];
        }
    }

    handleTeamChange(event) {
        //this.isLoading = true;
        this.activeFilter = 'team';
        this.selectedTeam = event.detail.value;

        getEmployeesByTeam({ teamName: String(this.selectedTeam) })
            .then(res => {
                //this.isLoading = false;
                this.employees = res.map(emp => ({
                    ...emp,
                    blockName: emp.Block__r ? emp.Block__r.Name : ''
                }));
            })
            .catch(err => console.error(err));
    }

    handleNameChange(event) {
        this.selectedName = event.target.value;
        this.activeFilter = 'name';

        this.debounce(() => {
            if (!this.selectedName) {
                this.employees = [];
                return;
            }

            getEmployeesByName({ empName: this.selectedName })
                .then(res => {
                    this.employees = res.map(emp => ({
                        ...emp,
                        blockName: emp.Block__r ? emp.Block__r.Name : ''
                    }));
                })
                .catch(err => console.error(err));
        });
    }

    handleRowSelection(event) {
        if (!this.isNameFilter) {
            this.selectedEmployees = event.detail.selectedRows;
            return;
        }

        const currentSelectedRows = event.detail.selectedRows;
        const currentSelectedIds = new Set(currentSelectedRows.map(r => r.Id));
        const visibleIds = new Set(this.employees.map(e => e.Id));

        // 1️⃣ Add newly selected rows
        currentSelectedRows.forEach(row => {
            if (!this.accumulatedSelectedEmployees.some(e => e.Id === row.Id)) {
                this.accumulatedSelectedEmployees = [
                    ...this.accumulatedSelectedEmployees,
                    row
                ];
            }
        });

        // 2️⃣ Remove explicitly deselected rows (only from visible ones)
        this.accumulatedSelectedEmployees = this.accumulatedSelectedEmployees.filter(emp => {
            // invisible → keep
            if (!visibleIds.has(emp.Id)) return true;

            // visible + selected → keep
            if (currentSelectedIds.has(emp.Id)) return true;

            // visible + unchecked → user deselected → remove
            return false;
        });

        // 3️⃣ Sync checkboxes
        this.selectedRowIds = this.accumulatedSelectedEmployees.map(e => e.Id);
    }

    openModal() {
        let employeesToCheck = this.isNameFilter ? this.accumulatedSelectedEmployees : this.selectedEmployees;

        if (employeesToCheck.length === 0) {
            this.showToast('Error', 'Select at least one employee', 'error');
            return;
        }
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
    }

    handleBlockChange(event) {
        this.selectedBlock = String(event.detail.value);
        this.fetchAvailableSeats();
    }

    handleGroupChange(event) {
        this.selectedGroup = event.detail.value;
        this.fetchAvailableSeats();
    }

    updateRecords() {
        let ids = this.isNameFilter
            ? this.accumulatedSelectedEmployees.map(emp => emp.Id)
            : this.selectedEmployees.map(emp => emp.Id);

        bulkUpdateEmployees({ employeeIds: ids, blockId: this.selectedBlock, groupName: this.selectedGroup })
            .then(() => {
                this.showToast('Success', 'Employees updated successfully', 'success');
                this.closeModal();
                publish(this.messageContext, APPROVAL_REFRESH, { refresh: true });

                // Clear accumulated selection after update if it's a name search
                if (this.isNameFilter) {
                    this.accumulatedSelectedEmployees = [];
                }

                // Refresh based on active filter
                if (this.activeFilter === 'team') {
                    return getEmployeesByTeam({ teamName: String(this.selectedTeam) });
                } else if (this.activeFilter === 'name') {
                    return getEmployeesByName({ empName: this.selectedName });
                }
            })
            .then(updated => {
                this.employees = updated.map(emp => ({
                    ...emp,
                    blockName: emp.Block__r ? emp.Block__r.Name : ''
                }));
            })
            .catch(error => {
                console.error(JSON.stringify(error));

                let message = 'Update failed';
                if (error?.body?.message) message = error.body.message;
                else if (error?.body?.pageErrors?.length) message = error.body.pageErrors[0].message;
                else if (error?.body?.fieldErrors) {
                    const keys = Object.keys(error.body.fieldErrors);
                    if (keys.length) message = error.body.fieldErrors[keys[0]][0].message;
                }

                this.showToast('Error', message, 'error');
            });
    }
    
    getSelectedEmployeeGroups() {
        const employees = this.isNameFilter
            ? this.accumulatedSelectedEmployees
            : this.selectedEmployees;

        return [...new Set(employees.map(emp => emp.Group__c))];
    }

    getSelectedEmployeeBlocks() {
        const employees = this.isNameFilter
            ? this.accumulatedSelectedEmployees
            : this.selectedEmployees;

        return [...new Set(employees.map(emp => emp.Block__c))];
    }


    fetchAvailableSeats() {
        if(!this.selectedBlock || !this.selectedGroup) {
            this.availableSeats = null;
            return;
        }

        getAvailableSeats({ blockId: this.selectedBlock, groupName: this.selectedGroup })
            .then(seats => {
                this.availableSeats = seats;
            })
            .catch(err => {
                console.error(err);
                this.availableSeats = null;
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

    delayTimeout;
    debounce(callback, delay = 500) {
        clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            callback();
        }, delay);
    }
 
}
