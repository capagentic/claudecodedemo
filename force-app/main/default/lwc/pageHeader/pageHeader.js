import { LightningElement, api } from 'lwc';

export default class PageHeader extends LightningElement {
    @api titleValue;
    @api subtitleValue;
    @api iconName;
}