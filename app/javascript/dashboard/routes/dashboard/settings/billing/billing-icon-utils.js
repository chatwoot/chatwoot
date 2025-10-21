import package1 from 'dashboard/assets/images/payment/package1.png'
import package2 from 'dashboard/assets/images/payment/package2.png'
import package3 from 'dashboard/assets/images/payment/package3.png'
import package4 from 'dashboard/assets/images/payment/package4.png'
import package5 from 'dashboard/assets/images/payment/package5.png'
import package6 from 'dashboard/assets/images/payment/package6.png'

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
    } else if (planName === 'PREMIUM') {
        return package5
    } else if (planName === 'PERTALITE') {
        return package3
    } else if (planName === 'PERTAMAX') {
        return package6
    } else if (planName === 'PERTAMAX TURBO') {
        return package2
    } else if (planName === 'CUSTOM') {
        return package4
    }
    return undefined
}