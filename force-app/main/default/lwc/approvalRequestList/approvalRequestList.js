import { LightningElement, wire } from 'lwc';
import getApprovalRequests from '@salesforce/apex/SAS_Approval_Request_Controller.getApprovalRequests';
import processApproval from '@salesforce/apex/SAS_Approval_Request_Controller.processApproval';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';



export default class ApprovalRequestList extends NavigationMixin(LightningElement) {

    approvals;
    wiredResult;

    isApprove = true;
    selectedWorkItemId;
    selectedRecordId;

    /* ---------- DATA ---------- */

    @wire(getApprovalRequests, { status: 'Pending' })
    wiredApprovals(result) {
        this.wiredResult = result;
        if (result.data) {
            this.approvals = result.data;
        }
    }

    get hasApprovals() {
        return this.approvals && this.approvals.length > 0;
    }

    handleOpenRecord(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.target.dataset.id,
                actionName: 'view'
            }
        });
    }

    handleRefresh() {
        // Refresh the wired approvals
        return refreshApex(this.wiredResult);
    }

}
