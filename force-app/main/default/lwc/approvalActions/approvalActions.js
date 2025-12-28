import { LightningElement, api, wire } from 'lwc';
import getApprovalRequestsByRecordId from '@salesforce/apex/SAS_Approval_Request_Controller.getApprovalRequestsByRecordId';
import processApproval from '@salesforce/apex/SAS_Approval_Request_Controller.processApproval';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { publish, MessageContext } from 'lightning/messageService';
import APPROVAL_REFRESH from '@salesforce/messageChannel/BlockSummaryRefresh__c';

export default class ApprovalActions extends LightningElement {
    
    @api recordId;
    workItemId;
    wiredResult;

    isModalOpen = false;

    @wire(MessageContext)
    messageContext;

    get hasWorkItem() {
        return !!this.workItemId;
    }

    @wire(getApprovalRequestsByRecordId, { recordId: '$recordId' })
    wiredWorkItems({ data, error }) {
        if (data && data.length > 0) {
            this.workItemId = data[0].Id; // 👈 ONLY the WorkItem Id
        } else if (error) {
            console.error(error);
        }
    }


    openApproveModal(event) {
        this.openModal(event, true);
    }

    openRejectModal(event) {
        this.openModal(event, false);
    }

    openModal(event, isApprove) {
        this.isApprove = isApprove;
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
    }

    get modalTitle() {
        return this.isApprove ? 'Approve Request' : 'Reject Request';
    }

    get flowInputVariables() {
        return [
            {
                name: 'recordId',
                type: 'String',
                value: this.recordId
            }
        ];
    }

    handleFlowStatus(event) {
        if (event.detail.status === 'FINISHED') {
            this.processApprovalAfterFlow();
        }
    }

    processApprovalAfterFlow() {
        processApproval({
            workItemId: this.workItemId,
            action: this.isApprove ? 'Approve' : 'Reject'
        })
        .then(() => {
            this.showToast(
                'Success',
                `Request ${this.isApprove ? 'approved' : 'rejected'} successfully`,
                'success'
            );
            this.closeModal();
            publish(this.messageContext, APPROVAL_REFRESH, { refresh: true });
            this.dispatchEvent(new CustomEvent('refreshparent'));
            this.workItemId = null;
        })
        .catch(error => {
            this.showToast('Error', error.body.message, 'error');
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    
}
