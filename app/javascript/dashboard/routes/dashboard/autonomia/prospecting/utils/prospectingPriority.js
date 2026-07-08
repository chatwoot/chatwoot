export const priorityValue = lead => {
  const value = lead?.priority_score ?? lead?.score;
  if (value === null || value === undefined || value === '') return null;

  return Math.max(0, Math.min(100, Math.round(Number(value))));
};

export const priorityTheme = priority => {
  if (priority >= 75) {
    return {
      ring: '#10b981',
      ringBg: '#d1fae5',
      ringText: '#065f46',
      cardBg: 'bg-n-teal-2',
      title: 'Lead muito quente',
      titleClass: 'text-n-teal-11',
    };
  }

  if (priority >= 50) {
    return {
      ring: '#3b82f6',
      ringBg: '#dbeafe',
      ringText: '#1e40af',
      cardBg: 'bg-n-blue-2',
      title: 'Oportunidade alta',
      titleClass: 'text-n-blue-11',
    };
  }

  if (priority >= 25) {
    return {
      ring: '#f59e0b',
      ringBg: '#fef3c7',
      ringText: '#92400e',
      cardBg: 'bg-n-amber-2',
      title: 'Lead morno',
      titleClass: 'text-n-amber-11',
    };
  }

  return {
    ring: '#ef4444',
    ringBg: '#fee2e2',
    ringText: '#991b1b',
    cardBg: 'bg-n-ruby-2',
    title: 'Prioridade baixa',
    titleClass: 'text-n-ruby-11',
  };
};

const toneClass = tone => {
  const classes = {
    pain: {
      card: 'bg-n-ruby-2 border-n-ruby-5 text-n-ruby-11',
      iconClass: 'text-n-ruby-11',
    },
    opportunity: {
      card: 'bg-n-amber-2 border-n-amber-5 text-n-amber-11',
      iconClass: 'text-n-amber-11',
    },
    positive: {
      card: 'bg-n-teal-2 border-n-teal-5 text-n-teal-11',
      iconClass: 'text-n-teal-11',
    },
    neutral: {
      card: 'bg-n-slate-2 border-n-slate-5 text-n-slate-11',
      iconClass: 'text-n-slate-10',
    },
  };

  return classes[tone] || classes.neutral;
};

const googleRankTone = searchRank => {
  if (searchRank <= 3) return 'positive';
  if (searchRank <= 10) return 'neutral';

  return 'opportunity';
};

const ratingTone = rating => {
  if (rating >= 4.5) return 'positive';
  if (rating >= 4) return 'neutral';

  return 'opportunity';
};

const reviewsTone = reviews => {
  if (reviews >= 100) return 'positive';
  if (reviews >= 20) return 'neutral';

  return 'opportunity';
};

export const leadPrioritySignals = lead => {
  const signals = [];
  const hasSite = Boolean(lead?.website);
  const hasPhone = Boolean(lead?.phone);
  const rating = Number(lead?.rating || 0);
  const reviews = Number(lead?.reviews_count || 0);
  const searchRank = Number(lead?.search_rank || 0);

  signals.push({
    key: 'website',
    label: hasSite ? 'Tem site' : 'Sem site',
    icon: hasSite ? 'i-lucide-globe' : 'i-lucide-globe-2',
    ...toneClass(hasSite ? 'positive' : 'pain'),
  });

  signals.push({
    key: 'phone',
    label: hasPhone ? 'Tem fone' : 'Sem fone',
    icon: hasPhone ? 'i-lucide-phone' : 'i-lucide-phone-off',
    ...toneClass(hasPhone ? 'positive' : 'pain'),
  });

  if (searchRank > 0) {
    signals.push({
      key: 'rank',
      label: `#${searchRank} Google`,
      icon: 'i-lucide-map-pin',
      ...toneClass(googleRankTone(searchRank)),
    });
  }

  if (rating > 0 && signals.length < 4) {
    signals.push({
      key: 'rating',
      label: `${rating.toFixed(1)} estrelas`,
      icon: 'i-lucide-star',
      ...toneClass(ratingTone(rating)),
    });
  }

  if (reviews > 0 && signals.length < 4) {
    signals.push({
      key: 'reviews',
      label: `${reviews} avaliações`,
      icon: 'i-lucide-message-square-text',
      ...toneClass(reviewsTone(reviews)),
    });
  }

  return signals.slice(0, 4);
};
