package com.localcluster.crm.customer;

import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/customers")
public class CustomerController {

  private final CustomerRepository customerRepository;

  public CustomerController(CustomerRepository customerRepository) {
    this.customerRepository = customerRepository;
  }

  @GetMapping
  public List<Customer> list() {
    return customerRepository.findAll();
  }

  @GetMapping("/{id}")
  public Customer byId(@PathVariable Long id) {
    return customerRepository.findById(id)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Customer not found"));
  }

  @PostMapping
  @ResponseStatus(HttpStatus.CREATED)
  public Customer create(@Valid @RequestBody CustomerRequest request) {
    Customer customer = new Customer();
    customer.setName(request.name());
    customer.setEmail(request.email());
    customer.setCompany(request.company());
    customer.setStatus(request.status());
    return customerRepository.save(customer);
  }

  @PutMapping("/{id}")
  public Customer update(@PathVariable Long id, @Valid @RequestBody CustomerRequest request) {
    Customer customer = customerRepository.findById(id)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Customer not found"));

    customer.setName(request.name());
    customer.setEmail(request.email());
    customer.setCompany(request.company());
    customer.setStatus(request.status());
    return customerRepository.save(customer);
  }

  @DeleteMapping("/{id}")
  @ResponseStatus(HttpStatus.NO_CONTENT)
  public void delete(@PathVariable Long id) {
    if (!customerRepository.existsById(id)) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Customer not found");
    }
    customerRepository.deleteById(id);
  }
}
