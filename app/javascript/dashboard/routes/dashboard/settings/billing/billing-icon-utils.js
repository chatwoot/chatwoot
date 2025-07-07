import package1 from 'dashboard/assets/images/payment/package1.png'
import package2 from 'dashboard/assets/images/payment/package2.png'
import package3 from 'dashboard/assets/images/payment/package3.png'
import package4 from 'dashboard/assets/images/payment/package4.png'

export function getPlanIcon(planName) {
    planName = planName?.toUpperCase()
    if (planName === 'FREE TRIAL') {
        return package1
    } else if (planName === 'STARTER') {
        return package2
    } else if (planName === 'GROWTH') {
        return package3
    } else if (planName === 'ENTERPRISE') {
        return package4
    }
    return undefined
}