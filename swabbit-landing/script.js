/* ============================================
   SWABBIT Landing Page — JavaScript
   Scroll animations, navbar, counter, scroll CTA
   ============================================ */

// ---- Navbar scroll shadow ----
const navbar = document.getElementById('navbar');
window.addEventListener('scroll', () => {
  navbar.classList.toggle('scrolled', window.scrollY > 10);
});

// ---- Scroll CTA ----
function scrollToCTA() {
  document.getElementById('waitlist').scrollIntoView({ behavior: 'smooth' });
}

// ---- Reveal-on-scroll (Intersection Observer) ----
const revealElements = document.querySelectorAll('.reveal');

const revealObserver = new IntersectionObserver((entries) => {
  entries.forEach((entry) => {
    if (entry.isIntersecting) {
      entry.target.classList.add('visible');
      revealObserver.unobserve(entry.target);
    }
  });
}, {
  threshold: 0.15,
  rootMargin: '0px 0px -40px 0px'
});

revealElements.forEach((el) => revealObserver.observe(el));

// ---- Animated counter for Social Proof stats ----
const statNumbers = document.querySelectorAll('.stat__number[data-target]');

function animateCounter(el) {
  const target = parseInt(el.dataset.target, 10);
  const suffix = el.dataset.suffix || '';
  const textOverride = el.dataset.text || '';

  if (target === 0 && textOverride) {
    el.textContent = textOverride;
    return;
  }

  let current = 0;
  const increment = Math.max(1, Math.ceil(target / 50));
  const duration = 1200;
  const stepTime = duration / (target / increment);

  const timer = setInterval(() => {
    current += increment;
    if (current >= target) {
      current = target;
      clearInterval(timer);
    }
    el.textContent = current + suffix;
  }, stepTime);
}

const counterObserver = new IntersectionObserver((entries) => {
  entries.forEach((entry) => {
    if (entry.isIntersecting) {
      animateCounter(entry.target);
      counterObserver.unobserve(entry.target);
    }
  });
}, { threshold: 0.5 });

statNumbers.forEach((el) => counterObserver.observe(el));

// ---- Staggered reveal for cards/steps ----
document.querySelectorAll('.benefit-card.reveal, .step.reveal').forEach((el, i) => {
  el.style.transitionDelay = `${i * 0.12}s`;
});
