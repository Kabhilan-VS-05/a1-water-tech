# A1 Water Tech

This repository contains the existing A1 Water Tech application stack and supporting project documents.

## Main Apps

- `a1-water-online-shop`
  React customer storefront
- `a1_tech_billing`
  Flutter admin and billing application
- `aws-lambdas/products-api`
  AWS Lambda backend for products and related APIs

## Repository Structure

```text
A1 Water Tech/
|-- a1-water-online-shop/
|-- a1_tech_billing/
|-- aws-lambdas/
|-- database/
|   |-- schemas/
|   `-- seeds/
|-- docs/
|   |-- activity/
|   |-- guides/
|   |-- overviews/
|   `-- project-details/
|-- amplify.yml
`-- README.md
```

## Supporting Folders

- `database/schemas`
  SQL schema files for AWS-backed modules
- `database/seeds`
  SQL seed files
- `docs/activity`
  migration and implementation activity logs
- `docs/guides`
  setup and migration guides
- `docs/overviews`
  high-level project overview documents
- `docs/project-details`
  project reference materials and attached assets

## Notes

- The recent Jenkins, Docker, Kubernetes, and Prometheus CI/CD files were removed.
- The accidental duplicate frontend copy from the repository root was removed.
- The application code remains in its original project folders.
