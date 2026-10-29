/**
 * 편집기 안에서 "/" 를 입력하면 Salesforce 전역 단축키(검색창 열기)가 먼저 반응하는 문제를 막는다.
 * 전역 단축키는 window 에서 듣기 때문에, 편집 영역에서 생긴 키 입력은 window 에 닿기 전에
 * 캡처 단계에서 전파를 멈춘다. 편집기 밖에서는 단축키가 그대로 동작한다.
 */
import { LightningElement, api } from "lwc";

const BLOCKED_KEYS = new Set(["/"]);

export default class SlashSafeEditor extends LightningElement {
    @api label = "Content";
    @api value = "";

    handleWindowKeydown = (event) => {
        if (!BLOCKED_KEYS.has(event.key)) {
            return;
        }
        const path = event.composedPath();
        if (path.includes(this.template.host)) {
            // 입력은 그대로 두고, 전역 단축키로 퍼지지만 않게 한다.
            event.stopPropagation();
        }
    };

    connectedCallback() {
        window.addEventListener("keydown", this.handleWindowKeydown, true);
    }

    disconnectedCallback() {
        window.removeEventListener("keydown", this.handleWindowKeydown, true);
    }

    handleInput(event) {
        this.value = event.target.value;
        this.dispatchEvent(new CustomEvent("change", { detail: { value: this.value } }));
    }
}