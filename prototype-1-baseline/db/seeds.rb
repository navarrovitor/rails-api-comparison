# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

TOPICS = [
  "Ruby on Rails", "API Design", "Database Optimization", "Caching Strategies",
  "Authentication", "Authorization", "Background Jobs", "WebSockets",
  "Microservices", "Docker", "CI/CD Pipelines", "Test-Driven Development",
  "Refactoring", "Design Patterns", "Performance Tuning", "Security Best Practices",
  "GraphQL", "REST vs SOAP", "Deployment Strategies", "Monitoring and Logging"
].freeze

INTROS = [
  "In this article, we explore the fundamentals of",
  "This guide provides a comprehensive overview of",
  "Understanding the core concepts behind",
  "A deep dive into the principles and practices of",
  "Practical strategies and techniques for working with",
  "An in-depth look at the challenges and solutions related to",
  "Best practices and real-world examples of implementing",
  "Everything you need to know about",
  "A step-by-step walkthrough for mastering",
  "Key insights and lessons learned from working with"
].freeze

Article.delete_all

500.times do |i|
  topic = TOPICS[i % TOPICS.length]
  intro = INTROS[i % INTROS.length]
  index = i + 1

  title = "Article #{index}: #{topic}"

  content = <<~TEXT
    #{intro} #{topic}. This is article number #{index} in our series covering modern software development practices.

    #{topic} is a critical area that every developer should understand. When building scalable applications,
    attention to #{topic.downcase} can make the difference between a system that performs well under load
    and one that struggles to handle real-world traffic.

    In practice, teams that invest in #{topic.downcase} consistently deliver better outcomes. The key is to
    start with the fundamentals and progressively apply more advanced techniques as the system grows.
    Article #{index} covers practical guidance you can apply immediately in your own projects.

    Common pitfalls when approaching #{topic.downcase} include neglecting edge cases, over-engineering
    solutions early on, and failing to measure before optimizing. By understanding these challenges up
    front, you can avoid the most frequent mistakes and build a solid foundation.

    The examples in this article are drawn from real production systems and reflect lessons learned
    over many years of engineering work. Whether you are just getting started or looking to deepen
    your expertise in #{topic.downcase}, this content will give you actionable takeaways.
  TEXT

  Article.create!(title: title, content: content.strip)
end

puts "Seeded #{Article.count} articles."
