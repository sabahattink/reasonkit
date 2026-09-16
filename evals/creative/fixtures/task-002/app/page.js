import content from '../content.json';

export default function Page() {
  return (
    <main>
      <section className="hero" aria-labelledby="page-title">
        <p className="eyebrow">{content.kicker}</p>
        <h1 id="page-title">{content.title}</h1>
        <p className="intro">{content.intro}</p>
        <a className="primary-link" href="#work">
          {content.primaryAction}
        </a>
      </section>

      <section id="work" className="work" aria-labelledby="work-title">
        <div>
          <p className="eyebrow">Selected work</p>
          <h2 id="work-title">Make the system legible.</h2>
        </div>
        <div className="project-grid">
          {content.projects.map((project) => (
            <article className="project-card" key={project.id}>
              <p className="project-index">{project.id}</p>
              <h3>{project.title}</h3>
              <p>{project.summary}</p>
            </article>
          ))}
        </div>
      </section>
    </main>
  );
}
